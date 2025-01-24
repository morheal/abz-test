# WordPress Setup with Terraform, Docker Compose, MySQL, and Redis

This repository contains Terraform configurations and Docker Compose setup to deploy a WordPress site with MySQL and Redis on AWS.

## Prerequisites

- AWS account
- Terraform installed
- Docker and Docker Compose installed
- SSH key pair for accessing EC2 instances

## Terraform Configuration

### Resources

- **EC2 Instance**: Hosts the WordPress site.
- **RDS MySQL**: Managed MySQL database for WordPress.
- **ElastiCache Redis**: Managed Redis instance for caching.
- **Security Groups**: Define access rules for the instances.
- **Subnets**: Define the network layout.

### Files

- `main.tf`: Main Terraform configuration file.
- `securityGroup.tf`: Security group definitions.
- `database.tf`: RDS MySQL configuration.
- `redis.tf`: ElastiCache Redis configuration.
- `docker-compose.yml`: Docker Compose configuration for local connection to MySQL and Redis instances
- `wp-config.php`: WordPress configuration file.

## Setup Instructions

### Step 1: Clone the Repository

```sh
git clone https://github.com/your-username/your-repo.git
cd your-repo
```

### Step 2: Configure AWS Credentials

```sh
aws configure
```

### Step 3: Initialize Terraform

```sh
terraform init
```

### Step 4: Apply Terraform Configuration

```sh
terraform apply
```

## Docker Compose Configuration
- The docker-compose.yml file sets up the following services:

- MySQL: The MySQL database for WordPress.
- Redis: The Redis instance for caching.

## License
- This project is licensed under the MIT License.