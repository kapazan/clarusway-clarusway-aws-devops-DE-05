//This Terraform Template creates five Compose enabled Docker Machines on EC2 Instances
//which are ready for Docker Swarm operations.
//Docker Machines will run on Amazon Linux 2 with custom security group
//allowing SSH (22), HTTP (80) and TCP(2377, 8080) connections from anywhere.
//User needs to select appropriate key name when launching the template.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  //  access_key = ""
  //  secret_key = ""
  //  If you have entered your credentials in AWS CLI before, you do not need to use these arguments.
}

resource "aws_instance" "tf-docker-machine" {
  ami             = "ami-06ca3ca175f37dd66"
  instance_type   = "t2.micro"
  key_name        = "oliver"
  //  Write your pem file name
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  count = 5
  tags = {
    Name = "Docker-Swarm-Instance-${count.index + 1}"
  }
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              # install docker-compose
              curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
	          EOF
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-swarm-sec-grde"
  tags = {
    Name = "docker-swarm-sec-groupde"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
//TCP port 2377 for cluster management communications
  ingress {
    from_port   = 2377
    protocol    = "tcp"
    to_port     = 2377
    self = true
  }
//UDP port 4789 for overlay network traffic
  ingress {
    from_port   = 4789
    protocol    = "udp"
    to_port     = 4789
    self = true
  }
//TCP and UDP port 7946 for communication among nodes
  ingress {
    from_port   = 7946
    protocol    = "tcp"
    to_port     = 7946
    self = true
  }

  ingress {
    from_port   = 7946
    protocol    = "udp"
    to_port     = 7946
    self = true
  }


  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_dns" {
  value = aws_instance.tf-docker-machine.*.public_dns
}

output "private_ip" {
  value = aws_instance.tf-docker-machine.*.private_ip
}
