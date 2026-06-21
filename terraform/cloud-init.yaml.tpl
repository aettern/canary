#!/bin/bash
set -e

# Update and install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl apt-transport-https unzip software-properties-common iptables-persistent git python3-venv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind virtualenv

# 1. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey="${tailscale_authkey}" --ssh

# 2. Install Wazuh Agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

WAZUH_MANAGER="${wazuh_manager_ip}" WAZUH_AGENT_PASSWORD="${wazuh_enrollment_password}" apt-get install wazuh-agent -y

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# 3. Setup Cowrie Honeypot
# Create cowrie user
adduser --disabled-password --gecos "" cowrie

# Clone Cowrie
su - cowrie -c "git clone https://github.com/cowrie/cowrie.git /home/cowrie/cowrie"

# Setup virtual environment and install Cowrie
su - cowrie -c "cd /home/cowrie/cowrie && python3 -m venv cowrie-env && source cowrie-env/bin/activate && python -m pip install --upgrade pip && python -m pip install -e ."

# Create a basic cowrie config (Cowrie uses defaults if this is empty)
su - cowrie -c "touch /home/cowrie/cowrie/etc/cowrie.cfg"

# Create systemd service for Cowrie
cat <<EOF > /etc/systemd/system/cowrie.service
[Unit]
Description=Cowrie SSH Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
Environment="PATH=/home/cowrie/cowrie/cowrie-env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/cowrie/cowrie/cowrie-env/bin/cowrie start
ExecStop=/home/cowrie/cowrie/cowrie-env/bin/cowrie stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cowrie
systemctl start cowrie

# 4. Connect Cowrie Logs to Wazuh Agent
cat <<EOF >> /var/ossec/etc/ossec.conf
<ossec_config>
  <localfile>
    <log_format>json</log_format>
    <location>/home/cowrie/cowrie/var/log/cowrie/cowrie.json</location>
  </localfile>
</ossec_config>
EOF
systemctl restart wazuh-agent

# 5. Configure iptables to redirect port 22 to 2222 ONLY on the public interface
# Try both common AWS interfaces since cloud-init network detection can occasionally be flaky
iptables -t nat -A PREROUTING -i ens5 -p tcp --dport 22 -j REDIRECT --to-port 2222 || true
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 22 -j REDIRECT --to-port 2222 || true

# Save iptables rules so they persist across reboots
netfilter-persistent save
