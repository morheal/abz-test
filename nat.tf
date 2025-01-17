# NAT Gateway Configuration for WordPress EC2 Setup

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_ip" {
  vpc = true
  tags = {
    Name = "nat-gateway-ip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_ip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "wordpress-nat-gateway"
  }
}

resource "aws_route_table" "wordpress_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }
}

resource "aws_route_table_association" "wordpress_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.wordpress_route_table.id
}

# Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id

  tags = {
    Name = "private-route-table"
  }
}

# Route for NAT Gateway in Private Route Table
resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_route_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
