terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.16"
        }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
    region     = "eu-west-1"
    shared_credentials_file = "/Users/admin/.aws/credentials"
}

#EC2 instance with subnet and VPC
resource "aws_instance" "wordpress_server" {
    ami           = "ami-0a094c309b87cc107"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.wordpress_ec2_sg.id]

    tags = {
        Name = "Wordpress Server"
    }
}