output "honeypot_public_ip" {
  description = "The public IP address to attack (Cowrie listens on port 22 here)"
  value       = aws_instance.honeypot.public_ip
}

output "instance_id" {
  description = "The EC2 instance ID"
  value       = aws_instance.honeypot.id
}
