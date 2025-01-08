# ElastiCache - Redis
resource "aws_elasticache_cluster" "wordpress_redis" {
  cluster_id = "wordpress-redis"
  engine = "redis"
  node_type = "cache.t3.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis7"
  port = 6379
  security_group_ids = [aws_security_group.wordpress_redis_sg.id]
  subnet_group_name = aws_elasticache_subnet_group.wordpress_redis_subnet.id
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "wordpress_redis_subnet" {
  name = "wordpress-redis-subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}