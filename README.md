# canary

A Cowrie SSH honeypot deployed on AWS with automated log forwarding to a self-hosted Wazuh SIEM. Attackers hit what looks like a real SSH server, but every login attempt, command, and file transfer is recorded and sent to your Wazuh dashboard as a security alert.

## How It Works

1. Terraform spins up an EC2 instance running Cowrie on port 2222
2. iptables redirects public port 22 traffic into Cowrie (the honeypot)
3. Tailscale provides a private overlay network for admin SSH access
4. The Wazuh agent watches Cowrie's JSON logs and ships them to your Wazuh manager
5. Custom Wazuh rules turn raw honeypot logs into categorized security alerts

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured with valid credentials
- An AWS key pair in your target region
- A [Tailscale](https://tailscale.com) account and auth key
- A running Wazuh manager (see [wazuh-local/README.md](wazuh-local/README.md) for local setup)

## Quick Start

1. Copy the example variables file and fill in your values:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # edit terraform/terraform.tfvars with your keys and IPs
   ```

2. Bring up the honeypot:
   ```bash
   ./scripts/up.sh
   ```

3. Wait a few minutes for cloud-init to finish installing everything, then test:
   ```bash
   ssh root@<PUBLIC_IP>   # try any password, Cowrie will let you in
   ```

4. Check your Wazuh dashboard under **Threat monitoring > Security events** and search for `rule.groups: cowrie`.

## Teardown

```bash
./scripts/down.sh
```

## Project Structure

```
canary/
├── scripts/
│   ├── up.sh                    # terraform init + apply
│   └── down.sh                  # terraform destroy
├── terraform/
│   ├── main.tf                  # EC2 instance, security group, AMI lookup
│   ├── variables.tf             # input variables (all secrets marked sensitive)
│   ├── outputs.tf               # public IP output
│   ├── cloud-init.yaml.tpl      # bootstrap script (Tailscale, Wazuh, Cowrie)
│   └── terraform.tfvars.example # example config
└── wazuh-local/
    ├── README.md                # how to run Wazuh manager locally
    └── rules/
        └── cowrie_rules.xml     # custom Wazuh rules for Cowrie events
```

## Wazuh Rules

Custom rules are in [`wazuh-local/rules/cowrie_rules.xml`](wazuh-local/rules/cowrie_rules.xml). They cover:

| Rule ID | Level | Event |
|---------|-------|-------|
| 110001 | 3 | Any Cowrie event (base rule) |
| 110002 | 5 | New SSH connection |
| 110003 | 7 | Failed login attempt |
| 110004 | 10 | Successful honeypot login |
| 110005 | 8 | Command executed by attacker |
| 110006 | 12 | File download/upload |

To apply these rules to your Wazuh manager:
```bash
docker cp wazuh-local/rules/cowrie_rules.xml single-node-wazuh.manager-1:/var/ossec/etc/rules/cowrie_rules.xml
docker exec single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart
```

## License

MIT