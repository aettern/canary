#!/bin/bash
set -e

cd "$(dirname "$0")/../terraform"
terraform init
terraform apply -auto-approve

echo ""
echo "=== Canary Honeypot is up! ==="
echo "Public IP (Bait): $(terraform output -raw honeypot_public_ip)"
echo ""
echo "Note: It may take a few minutes for cloud-init to finish installing Cowrie, Tailscale, and Wazuh."
