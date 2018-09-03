
#
#   Networking setup
##############################################

# Define the VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "Demo VPC"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Demo Public Subnet"
  }
}

# Central subnet (private)
resource "aws_subnet" "central_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Central Subnet"
  }
}

# Subnets for each location (private)
resource "aws_subnet" "alpha_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Alpha Subnet"
  }
}

resource "aws_subnet" "beta_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.30.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Beta Subnet"
  }
}

resource "aws_subnet" "gamma_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.40.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Gamma Subnet"
  }
}

resource "aws_subnet" "delta_subnet" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  cidr_block = "10.0.50.0/24"
  availability_zone = "us-east-2a"

  tags {
    Name = "Delta Subnet"
  }
}

# Define internet gateway
resource "aws_internet_gateway" "demo-gw" {
  vpc_id = "${aws_vpc.demo_vpc.id}"

  tags {
    Name = "Demo IGW"
  }
}

# Define route table
resource "aws_route_table" "demo-public-rt" {
  vpc_id = "${aws_vpc.demo_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.demo-gw.id}"
  }

  tags {
    Name = "Public Subent RT"
  }
}

# Assign the public RT to the public subnet
resource "aws_route_table_association" "demo-public-rt" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.demo-public-rt.id}"
}

# Define the security group for the public subnet
resource "aws_security_group" "demo-public-sg"{
  name = "demo_web_public"
  description = "Allow incoming SSH connections & ICMP traffic"

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.demo_vpc.id}"

  tags {
    Name = "Demo Public SG"
  }

}

# Define the security group for the private subnets
resource "aws_security_group" "demo-private-sg"{
  name = "demo_web_private"
  description = "Allow traffic from public subnet"

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  vpc_id = "${aws_vpc.demo_vpc.id}"

  tags {
    Name = "Demo Private SG"
  }

}

# Set up NAT Gateway

resource "aws_eip" "nat-gateway-eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.demo-gw"]
}

resource "aws_nat_gateway" "demo-nat" {
  allocation_id = "${aws_eip.nat-gateway-eip.id}"
  subnet_id = "${aws_subnet.public_subnet.id}"
  depends_on = ["aws_internet_gateway.demo-gw"]
}

resource "aws_route_table" "demo-private-rt" {
  vpc_id = "${aws_vpc.demo_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.demo-nat.id}"
  }

  tags {
    Name = "Private Subnet RT"
  }
}

resource "aws_route_table_association" "demo-central-rt" {
  subnet_id = "${aws_subnet.central_subnet.id}"
  route_table_id = "${aws_route_table.demo-private-rt.id}"
}
resource "aws_route_table_association" "demo-alpha-rt" {
  subnet_id = "${aws_subnet.alpha_subnet.id}"
  route_table_id = "${aws_route_table.demo-private-rt.id}"
}
resource "aws_route_table_association" "demo-beta-rt" {
  subnet_id = "${aws_subnet.beta_subnet.id}"
  route_table_id = "${aws_route_table.demo-private-rt.id}"
}
resource "aws_route_table_association" "demo-gamma-rt" {
  subnet_id = "${aws_subnet.gamma_subnet.id}"
  route_table_id = "${aws_route_table.demo-private-rt.id}"
}
resource "aws_route_table_association" "demo-delta-rt" {
  subnet_id = "${aws_subnet.delta_subnet.id}"
  route_table_id = "${aws_route_table.demo-private-rt.id}"
}

# Expose various network stuff

output "demo_vpc_id" {
  value = "${aws_vpc.demo_vpc.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}

output "central_subnet_id" {
  value = "${aws_subnet.central_subnet.id}"
}

output "alpha_subnet_id" {
  value = "${aws_subnet.alpha_subnet.id}"
}

output "beta_subnet_id" {
  value = "${aws_subnet.beta_subnet.id}"
}

output "gamma_subnet_id" {
  value = "${aws_subnet.gamma_subnet.id}"
}

output "delta_subnet_id" {
  value = "${aws_subnet.delta_subnet.id}"
}
