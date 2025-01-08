# RDS Instance
resource "aws_db_instance" "wordpress_db" {
  identifier = "wordpress-db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  username = "wordpress_rds_user"
  password = "wordpress_rds_2025"
  db_name = "wordpress_rds"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.wordpress_rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.wordpress_db_subnet.id
  publicly_accessible = false
}

# DB Subnet Group
resource "aws_db_subnet_group" "wordpress_db_subnet" {
  name = "wordpress-db-subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}