# Local Wazuh Manager

This folder is for running the Wazuh manager locally using Docker.

## Setup Steps (Wazuh 4.x)
1. Clone the wazuh-docker repository:
   ```bash
   git clone https://github.com/wazuh/wazuh-docker.git
   ```
2. Increase virtual memory for the indexer:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   # to persist across reboots, add vm.max_map_count=262144 to /etc/sysctl.conf
   ```
3. Navigate to the single-node setup and generate certificates:
   ```bash
   cd wazuh-docker/single-node
   docker compose -f generate-indexer-certs.yml run --rm generator
   ```
4. Start the stack:
   ```bash
   docker compose up -d
   ```
5. Access your dashboard at `https://localhost` (default creds: `admin` / `SecretPassword`). Change these immediately.

## Custom Rules

Cowrie honeypot rules live in [`rules/cowrie_rules.xml`](rules/cowrie_rules.xml). To load them into the manager:
```bash
docker cp rules/cowrie_rules.xml single-node-wazuh.manager-1:/var/ossec/etc/rules/cowrie_rules.xml
docker exec single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart
```
