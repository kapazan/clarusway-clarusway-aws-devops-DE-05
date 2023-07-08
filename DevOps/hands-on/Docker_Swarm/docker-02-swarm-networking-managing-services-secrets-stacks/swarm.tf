terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  name = "us-east-1"
}

data "template_file" "leader-master" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Leader-Manager
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker swarm init
  EOF
}

data "template_file" "manager" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Manager
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    dnf install python-pip -y
    pip install ec2instanceconnectcli
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
    --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token manager | grep -i 'docker')"
  EOF

}

data "template_file" "worker" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Worker
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    dnf install python-pip -y
    pip install ec2instanceconnectcli
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
     --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token worker | grep -i 'docker')"
  EOF

}

variable "myami" {
  default = "ami-06b09bfacae1453cb"
}

variable "instancetype" {
  default = "t2.micro"
}

variable "mykey" {
  default = "clarusway"
}

resource "aws_instance" "docker-machine-leader-manager" {
  ami = var.myami
  instance_type = var.instancetype
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  user_data = data.template_file.leader-master.rendered
  tags = {
    Name = "Docker-Swarm-Leader-Manager"
  }
}

resource "aws_instance" "docker-machine-managers" {
  ami             = var.myami
  instance_type   = var.instancetype
  key_name        = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  count = 2
  user_data = data.template_file.manager.rendered
  tags = {
    Name = "Docker-Swarm-Manager-${count.index + 1}"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}

resource "aws_instance" "docker-machine-workers" {
  ami             = var.myami
  instance_type   = var.instancetype
  key_name        = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  count = 2
  user_data = data.template_file.worker.rendered
  tags = {
    Name = "Docker-Swarm-Worker-${count.index + 1}"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}

variable "sg-ports-tcp" {
  default = [80, 22, 2377, 7946, 8080]
}

variable "sg-ports-udp" {
  default = [4789, 7946]
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-swarm-sec-gr-cw"
  tags = {
    Name = "swarm-sec-gr-cw"
  }
  dynamic "ingress" {
    for_each = var.sg-ports-tcp
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.sg-ports-udp
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_instance_profile" "ec2ecr-profile" {
  name = "swarmprofilecw"
  role = aws_iam_role.ec2fulltoecr.name
}

resource "aws_iam_role" "ec2fulltoecr" {
  name = "ec2roletoecrprojectcw"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ec2-user"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}

output "leader-manager-public-ip" {
  value = aws_instance.docker-machine-leader-manager.public_ip
}

output "manager-public-ip" {
  value = aws_instance.docker-machine-managers.*.public_ip
}

output "worker-public-ip" {
  value = aws_instance.docker-machine-workers.*.public_ip
}