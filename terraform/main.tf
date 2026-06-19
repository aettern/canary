terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Fetch the latest Ubuntu 24.04 LTS AMI dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "honeypot_sg" {
  name        = "canary-honeypot-sg"
  description = "Security group for Canary honeypot"

  # Allow inbound SSH from anywhere (this is the bait for Cowrie)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (needed for apt, tailscale, github, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "honeypot" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.honeypot_sg.id]

  user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
    tailscale_authkey         = var.tailscale_authkey
    wazuh_manager_ip          = var.wazuh_manager_ip
    wazuh_enrollment_password = var.wazuh_enrollment_password
  })

  tags = {
    Name = "canary-honeypot"
  }
}
