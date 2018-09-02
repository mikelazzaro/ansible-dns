
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

# Define the security group & IAM roles for bastion server
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

# TODO: Lock down these permissions!
data "aws_iam_policy_document" "bastion_iam_policy" {
  statement {
    actions = ["*"]
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_server_role"

  assume_role_policy = "${data.aws_iam_policy_document.bastion_iam_policy.json}"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = "${aws_iam_role.bastion_role.name}"
}

//
//resource "aws_iam_role" "bastion_role" {
//  name = "basion_server_role"
//  assume_role_policy
//}

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

  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.id}"

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

#
#   Output settings
##############################################

//output "bastion_ip" {
//  value = "${aws_eip_association.bastion_eip.public_ip}"
//}

output "public_subnet_id" {
  value = "${module.vpc.public_subnet_id}"
}

output "central_subnet_id" {
  value = "${module.vpc.public_subnet_id}"
}

output "alpha_subnet_id" {
  value = "${module.vpc.central_subnet_id}"
}

output "beta_subnet_id" {
  value = "${module.vpc.beta_subnet_id}"
}

output "gamma_subnet_id" {
  value = "${module.vpc.gamma_subnet_id}"
}

output "delta_subnet_id" {
  value = "${module.vpc.delta_subnet_id}"
}
