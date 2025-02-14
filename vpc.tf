# VPC Configuration
resource "aws_vpc" "wordpress_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wordpress-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress_vpc.id

  tags = {
    Name = "wordpress-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.wordpress_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-public-subnet"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.wordpress_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "wordpress-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.wordpress_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-1c"

  tags = {
    Name = "wordpress-private-subnet-2"
  }
}

resource "aws_network_acl" "wordpress_acl" {
  vpc_id = aws_vpc.wordpress_vpc.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
}