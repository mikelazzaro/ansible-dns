provider "aws" {
//  region = "us-east-2"
  region = "us-east-1"
}

resource "aws_instance" "example"{
  ami           = "ami-759bc50a"  // US-east-1 AMI
//  ami           = "ami-5e8bb23b"  // US-east-2 AMI
  instance_type = "t2.micro"
}