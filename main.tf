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
    ami           = "ami-0a094c309b87cc107"
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

    #Installing Required Packages
    provisioner "remote-exec" {
        inline = [
            "sudo yum install git -y",
            "sudo yum update -y",
            "sudo yum install -y httpd php php-mysqlnd"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Creating User and Setting Up Permissions
    provisioner "remote-exec" {
        inline = [
            "sudo useradd -m -s /bin/bash apache_user"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    # Setting Up Web Directory and SSH for apache_user
    provisioner "remote-exec" {
        inline = [
            "sudo mkdir -p /var/www/html",
            "sudo -u apache_user mkdir -p /home/apache_user/.ssh",
            "sudo cp /home/ec2-user/.ssh/id_rsa /home/apache_user/.ssh/id_rsa",
            "sudo cp /home/ec2-user/.ssh/known_hosts /home/apache_user/.ssh/known_hosts",
            "sudo chown -R apache_user:apache_user /home/apache_user/.ssh",
            "sudo chmod 600 /home/apache_user/.ssh/id_rsa",
            "sudo chown -R apache_user:apache_user /var/www/html",
            "sudo chmod -R 755 /var/www/html"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Cloning the Repository
    provisioner "remote-exec" {
        inline = [
            "sudo -u apache_user bash -c 'eval $(ssh-agent -s); ssh-add /home/apache_user/.ssh/id_rsa; git clone -b master git@github.com:morheal/abz-test-wordpress.git /var/www/html/'",
            "sudo chown -R apache_user:apache_user /var/www/html/"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    #Configuring Apache
    provisioner "remote-exec" {
        inline = [
            "sudo sed -i 's/User apache/User apache_user/' /etc/httpd/conf/httpd.conf",
            "sudo sed -i 's/Group apache/Group apache_user/' /etc/httpd/conf/httpd.conf",
            "sudo bash -c 'cat <<EOF > /etc/httpd/conf.d/wordpress.conf\n<VirtualHost *:80>\n    DocumentRoot /var/www/html\n    <Directory /var/www/html>\n        AllowOverride All\n        Require all granted\n    </Directory>\n    ErrorLog /var/log/httpd/wordpress-error.log\n    CustomLog /var/log/httpd/wordpress-access.log combined\n</VirtualHost>\nEOF'",
            "sudo chown -R apache_user:apache_user /var/www/html",
            "sudo chmod -R 755 /var/www/html",
            "sudo systemctl enable --now httpd"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
        }
    }

    /*
    provisioner "remote-exec" {

        inline = [
            "chmod 600 /home/ec2-user/.ssh/id_rsa",
            "eval $(ssh-agent -s)",
            "ssh-add /home/ec2-user/.ssh/id_rsa",
            "ssh-keyscan -H github.com >> /home/ec2-user/.ssh/known_hosts",
            "sudo yum install git -y",
            "sudo yum update -y",
            "sudo yum install -y httpd php php-mysqlnd",
            "sudo useradd -m -s /bin/bash apache_user",
            "echo 'apache_user:your_secure_password' | sudo chpasswd",
            "sudo mkdir -p /var/www/html",
            "sudo -u apache_user mkdir -p /home/apache_user/.ssh",
            "sudo cp /home/ec2-user/.ssh/id_rsa /home/apache_user/.ssh/id_rsa",
            "sudo cp /home/ec2-user/.ssh/known_hosts /home/apache_user/.ssh/known_hosts",
            "sudo chown -R apache_user:apache_user /home/apache_user/.ssh",
            "sudo chmod 600 /home/apache_user/.ssh/id_rsa",
            "sudo -u apache_user bash -c 'eval $(ssh-agent -s); ssh-add /home/apache_user/.ssh/id_rsa; git clone git@github.com:morheal/abz-test-wordpress.git /var/www/html/'",
            "sudo chown -R apache_user:apache_user /var/www/html/",
            "sudo sed -i 's/User apache/User apache_user/' /etc/httpd/conf/httpd.conf",
            "sudo sed -i 's/Group apache/Group apache_user/' /etc/httpd/conf/httpd.conf",
            "sudo systemctl enable --now httpd"
        ]

        connection {
            type        = "ssh"
            user        = "ec2-user"
            private_key = file("~/.ssh/id_rsa") # Path to your private SSH key
            host        = self.public_ip
            timeout     = "5m"

        }
    }
    */
    tags = {
        Name = "Wordpress Server"
    }
}