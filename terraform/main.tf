
#
#   Variable setup
##############################################

variable "bastion_public_ip" {}
variable "human_keypair_name" {}
variable "ansible_keypair_name" {}


#
#   General configuration
##############################################

# Basic AWS settings
provider "aws" {
  region = "us-east-2"
}

#
#   Networking setup
##############################################

# Moving to modules/vpc
module "vpc" {
  source = "modules/vpc"
}

//data "public_subnet" {
//
//}

#
#   Bastion setup
##############################################
//
//# Data sources
////data "aws_vpc"
//
# Define the security group for the private subnets
resource "aws_security_group" "demo-bastion-sg"{
  name = "demo_bastion"
  description = "Allow SSH traffic from all IPs"
//  vpc_id = "${aws_vpc.demo_vpc.id}"
  vpc_id = "${module.vpc.demo_vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Demo Bastion SG"
  }

}


//data "aws_ami" "ubuntu_1604" {
//  most_recent = true
//
//}

# Set up bastion instance
resource "aws_instance" "bastion" {
  # TODO - Organize!
  ami           = "ami-0552e3455b9bc8d50"
  instance_type = "t2.micro"
  key_name = "${var.human_keypair_name}"
  vpc_security_group_ids  = ["${aws_security_group.demo-bastion-sg.id}"]
  # Don't need to specify VPC, since subnet will take care of that
  subnet_id = "${module.vpc.public_subnet_id}"
  private_ip = "10.0.0.5"
  # TODO - get this set up
//  iam_instance_profile = "TODO"

  tags {
    Name = "Bastion Server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install python-pip -y",
      "pip install ansible",
      "git clone https://github.com/mikelazzaro/ansible-dns.git"
    ]
  }
//
//  provisioner "remote-exec" {
//    command = "sudo apt-get install python-pip"
//  }
//
//  provisioner "remote-exec" {
//    command = "pip install ansible"
//  }


//  provisioner "file" {
//    source = ""
//    destination = ""
//  }

//  provisioner "local-exec" {
//    command = "sudo apt-get update && sudo apt-get install python-pip && "
//  }
}

data aws_eip "bastion_eip" {
  public_ip = "${var.bastion_public_ip}"
}

resource "aws_eip_association" "bastion_eip" {
  instance_id = "${aws_instance.bastion.id}"
  allocation_id = "${data.aws_eip.bastion_eip.id}"
}

output "bastion_ip" {
  value = "${aws_eip_association.bastion_eip.public_ip}"
}