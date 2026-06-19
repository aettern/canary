variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the existing EC2 key pair to use for admin SSH access"
  type        = string
}

variable "tailscale_authkey" {
  description = "Tailscale auth key (preferably an ephemeral one)"
  type        = string
  sensitive   = true
}

variable "wazuh_manager_ip" {
  description = "The Tailscale IP address of your local Wazuh manager"
  type        = string
}

variable "wazuh_enrollment_password" {
  description = "Password for Wazuh agent enrollment"
  type        = string
  sensitive   = true
}
