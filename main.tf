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
    shared_credentials_files = ["/Users/admin/.aws/credentials"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

#EC2 instance with subnet and VPC
resource "aws_instance" "wordpress_server" {
    ami           = "ami-0fa8eaa89da54d46b"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    key_name      = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [aws_security_group.wordpress_ec2_sg.id]

    provisioner "file" {
        source      = "~/.ssh/id_rsa"
        destination = "/home/ec2-user/.ssh/id_rsa"

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa")
            host        = self.public_ip
        }
    }

    #Setting Up SSH Key and Known Hosts
    provisioner "remote-exec" {
        inline = [
            "chmod 600 /home/ec2-user/.ssh/id_rsa",
            "eval $(ssh-agent -s)",
            "ssh-add /home/ec2-user/.ssh/id_rsa",
            "ssh-keyscan -H github.com >> /home/ec2-user/.ssh/known_hosts"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Installing LAMP Stack
    provisioner "remote-exec" {
        inline = [
            "sudo yum update -y",
            "sudo yum install git -y",
            "sudo amazon-linux-extras install mariadb10.5 -y",
            "sudo amazon-linux-extras install php8.2 -y",
            "sudo yum install php-gd -y",
            "sudo yum install -y httpd",
            "sudo systemctl start httpd"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Add ec2-user to apache group and set permissions
    provisioner "remote-exec" {
        inline = [
            "sudo usermod -a -G apache ec2-user",
            "sudo chown -R ec2-user:apache /var/www",
            "sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \\;",
            "find /var/www -type f -exec sudo chmod 0664 {} \\;",
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Cloning the Wordpress Config from Repository 
    provisioner "remote-exec" {
        inline = [
            "sudo ssh-add /home/apache_user/.ssh/id_rsa",
            "git clone -b master git@github.com:morheal/abz-test-wp.git /var/www/html/",
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Downloading Wordpress
    provisioner "remote-exec" {
        inline = [
            "wget https://wordpress.org/latest.tar.gz",
            "tar -xzf latest.tar.gz",
            "cp -r wordpress/* /var/www/html/"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Allowing Apache to Rewrite and Override
    provisioner "remote-exec" {
        inline = [
            "sudo sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/httpd/conf/httpd.conf",
            "sudo sed -i '/<Directory \"\\/var\\/www\\/html\">/,/<\\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }
    
    #Setting Permissions for Apache User/Group and Restarting Apache
    provisioner "remote-exec" {
        inline = [
            "sudo chown -R apache /var/www",
            "sudo chgrp -R apache /var/www",
            "sudo chmod 2775 /var/www",
            "find /var/www -type d -exec sudo chmod 2775 {} \\;",
            "find /var/www -type f -exec sudo chmod 0644 {} \\;",
            "sudo systemctl restart httpd"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }
    
    tags = {
        Name = "Wordpress Server"
    }
}