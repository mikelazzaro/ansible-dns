
#
#   Variable setup
##############################################

variable "local_ssh_folder" {}


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

#
#   EC2 instance setup (bastion & central DNS)
##############################################

data aws_ami "ubuntu_1604" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
    ]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}

# Define the security group & IAM roles for bastion server
resource "aws_security_group" "phoenix-bastion-sg"{
  name = "phoenix_bastion"
  description = "Allow SSH & ICMP traffic from all IPs"
  vpc_id = "${module.vpc.phoenix_vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Phoenix Bastion SG"
  }

}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_server_role"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}


resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = "${aws_iam_role.bastion_role.name}"
}

# TODO: Lock down these permissions!
data "aws_iam_policy_document" "basion_role_policy_document" {
  statement {
    effect = "Allow"
    resources = ["arn:aws:ec2:*"]
    actions = ["ec2:*"]
  }
}
//data "aws_iam_policy_document" "basion_role_policy_document" {
//  statement {
//    effect = "Allow"
//    resources = ["*"]
//    actions = ["*"]
//  }
//}

resource "aws_iam_role_policy" "basion_role_policy" {
  policy = "${data.aws_iam_policy_document.basion_role_policy_document.json}"
  role = "${aws_iam_role.bastion_role.id}"
}

# Set up bastion instance
resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu_1604.id}"
  instance_type = "t2.micro"
  key_name = "human"
  vpc_security_group_ids  = ["${aws_security_group.phoenix-bastion-sg.id}"]

  # Don't need to specify VPC, since subnet will take care of that
  subnet_id = "${module.vpc.public_subnet_id}"
  private_ip = "10.0.0.5"
  associate_public_ip_address = true

  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.id}"

  tags {
    Name = "Bastion Server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install python-pip -y",
      "pip install ansible",
      "git clone https://github.com/mikelazzaro/ansible-dns.git",
      "mkdir -p /home/ubuntu/.ssh"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("${var.local_ssh_folder}/human.pem")}"
    }
  }

  provisioner "file" {
    source = "${var.local_ssh_folder}/human.pem"
    destination = "/home/ubuntu/.ssh/human.pem"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("${var.local_ssh_folder}/human.pem")}"
    }
  }

  provisioner "file" {
    source = "${var.local_ssh_folder}/ansible.pem"
    destination = "/home/ubuntu/.ssh/ansible.pem"

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("${var.local_ssh_folder}/human.pem")}"
    }
  }
}

resource "aws_eip" "bastion_eip" {
  vpc = true
  instance = "${aws_instance.bastion.id}"
}

resource "aws_security_group" "phoenix-internal-sg"{
  name = "phoenix_internal_sg"
  description = "Allow SSH, DNS, and ICMP traffic between internal hosts"
  vpc_id = "${module.vpc.phoenix_vpc_id}"

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # DNS
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # ICMP
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Phoenix Internal SG"
  }

}


#
#   Central DNS setup
##############################################

resource "aws_instance" "central-dns01" {

  ami                     = "${data.aws_ami.ubuntu_1604.id}"
  instance_type           = "t2.micro"
  key_name                = "ansible"
  vpc_security_group_ids  = ["${aws_security_group.phoenix-internal-sg.id}"]
  subnet_id               = "${module.vpc.central_subnet_id}"
  private_ip              = "10.0.10.100"

  tags {
    Name                  = "Central DNS 01"
  }
}

#
#   Output settings
##############################################

output "bastion_ip" {
  value = "${aws_eip.bastion_eip.public_ip}"
}