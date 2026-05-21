#!/bin/bash

# Exit immediately if any command fails
set -e

echo "=========================================="
echo " Starting Full Automated Exam Deployment "
echo "=========================================="

# 1. Update system software lists
sudo apt update

# 2. Install Nginx (Reverse Proxy)
sudo apt install nginx -y

# 3. Add HashiCorp Repository & Install Vault (Secret Manager)
sudo apt-get install -y apt-transport-https software-properties-common wget
wget -O- [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) \$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault -y

# 4. Start Vault in Dev Mode and AUTOMATICALLY capture the Root Token
sudo systemctl stop vault || true
vault server -dev > /tmp/vault.log 2>&1 &
sleep 3 # Give Vault a brief moment to boot up

# Automatically extract the fresh Root Token from the logs
DYNAMIC_TOKEN=\$(grep "Root Token:" /tmp/vault.log | awk '{print \$3}')
echo "Captured Active Vault Token: \$DYNAMIC_TOKEN"

# 5. Authenticate with Vault and inject our secret key
export VAULT_ADDR='[http://127.0.0.1:8200](http://127.0.0.1:8200)'
vault login "\$DYNAMIC_TOKEN"
vault kv put secret/myapp my-super-secret-key="PerfectGrade10!"

# 6. Install Python, Flask, and the Vault client tools
sudo apt install python3-pip python3-flask -y
pip3 install hvac --break-system-packages

# 7. Write the Python Web Application file using the dynamic token variable
cat << EOF > app.py
from flask import Flask
import hvac

app = Flask(__name__)
vault_client = hvac.Client(url='[http://127.0.0.1:8200](http://127.0.0.1:8200)', token='${DYNAMIC_TOKEN}')

@app.route('/')
def home():
    try:
        read_response = vault_client.secrets.kv.v2.read_secret_version(path='myapp')
        secret_value = read_response['data']['data']['my-super-secret-key']
        return f"<h1>Exam Web Application</h1><p><b>Status:</b> Securely connected to HashiCorp Vault.</p><p><b>Retrieved Key:</b> <span style='color: green;'>{secret_value}</span></p>"
    except Exception as e:
        return f"<h1>Error fetching secret</h1><p>{str(e)}</p>"

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
EOF

# 8. Start the Web Application in the background
sudo pkill -f app.py || true
python3 app.py &

# 9. Install Prometheus & Grafana (Monitoring Stack)
sudo apt install prometheus -y
sudo mkdir -p /etc/apt/keyrings
wget -q -O - [https://apt.grafana.com/gpg.key](https://apt.grafana.com/gpg.key) | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] [https://apt.grafana.com](https://apt.grafana.com) stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install grafana -y
sudo systemctl enable --now prometheus grafana-server

# 10. Configure Grafana to use the /dashboard/ base path
cat << 'EOF' > /etc/grafana/grafana.ini
[server]
domain = localhost
root_url = %(protocol)s://%(domain)s:%(http_port)s/dashboard/
EOF
sudo systemctl restart grafana-server

# 11. Overwrite Nginx configuration rules with our optimized routing
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name _;

    location /dashboard/ {
        proxy_pass [http://127.0.0.1:3000/](http://127.0.0.1:3000/);
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location / {
        proxy_pass [http://127.0.0.1:5000](http://127.0.0.1:5000);
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# 12. Restart Nginx to finalize deployment
sudo systemctl restart nginx

echo "=========================================="
echo " Deployment Finished Successfully!        "
echo "=========================================="