# Cloud Programming Exam — Infrastructure Automation

A fully automated, single-script deployment of a cloud-native infrastructure stack on Ubuntu, covering reverse proxying, secrets management, a Python web application, and a monitoring suite.

---

## Architecture Overview

```
Client (Port 80)
      │
      ▼
  [ Nginx ]  ──── Reverse Proxy / Ingress
      │
      ├── /            ──▶  Flask App       (127.0.0.1:5000)
      └── /dashboard/  ──▶  Grafana         (127.0.0.1:3000)

  [ HashiCorp Vault ]  ──── Secrets Manager (127.0.0.1:8200)
      └── Read by Flask app at startup

  [ Prometheus ]       ──── Metrics Scraper (127.0.0.1:9090)
      └── Scraped by Grafana
```

| Layer           | Component             | Port | Access                  |
| --------------- | --------------------- | ---- | ----------------------- |
| Ingress / Proxy | Nginx                 | 80   | Public                  |
| Application     | Python Flask          | 5000 | Via Nginx `/`           |
| Secrets Manager | HashiCorp Vault (dev) | 8200 | Internal only           |
| Metrics         | Prometheus            | 9090 | Internal only           |
| Dashboard       | Grafana               | 3000 | Via Nginx `/dashboard/` |

> **Note:** Vault runs in **dev mode**, which is in-memory only. All secrets are lost if Vault or the machine restarts. This is intentional for exam/demo purposes — do not use in production.

---

## Prerequisites

- A clean Ubuntu 22.04 (or 24.04) VM or instance
- SSH access with a user that has `sudo` privileges
- Internet access (to download packages)

---

## Deployment — 3 Commands

```bash
# 1. Download the deployment script
wget -O deploy.sh "https://raw.githubusercontent.com/davidspringean12/cloud-programming-exam/refs/heads/main/deploy.sh"

# 2. Make it executable
chmod +x deploy.sh

# 3. Run it
sudo ./deploy.sh
```

The script is fully automated — no interactive prompts, no manual edits required.

---

## What the Script Does

1. **Updates** the system package lists
2. **Installs Nginx** as the reverse proxy
3. **Installs HashiCorp Vault** from the official HashiCorp APT repository
4. **Starts Vault in dev mode** and captures the root token automatically
5. **Writes a secret** (`my-super-secret-key`) into Vault's KV store
6. **Installs Python 3, Flask, and hvac** (the Vault Python client)
7. **Generates `app.py`** — a Flask app that reads and displays the secret from Vault
8. **Installs Prometheus and Grafana** from their official repositories
9. **Configures Grafana** to serve under the `/dashboard/` path
10. **Writes the Nginx config** with path-based routing to Flask and Grafana
11. **Validates and restarts Nginx** to apply the configuration

---

## Verifying the Deployment

Once the script finishes, you should see:

```
==========================================
 Deployment Finished Successfully!
==========================================

 Flask app:  http://localhost/
 Grafana:    http://localhost/dashboard/
 Vault UI:   http://localhost:8200/ui
==========================================
```

| Service   | URL                           | Expected                             |
| --------- | ----------------------------- | ------------------------------------ |
| Flask App | `http://<your-ip>/`           | Displays secret retrieved from Vault |
| Grafana   | `http://<your-ip>/dashboard/` | Grafana login page                   |
| Vault UI  | `http://<your-ip>:8200/ui`    | Vault web interface                  |

---

## Known Limitations

- **Vault dev mode**: Data is in-memory only and lost on restart. A production deployment would use a persistent Vault backend with proper unseal keys.
- **Flask token**: The Vault root token is baked into `app.py` at generation time. If Vault restarts and issues a new token, the app will fail to authenticate until `deploy.sh` is re-run.
- **No TLS**: All traffic is served over plain HTTP. A production setup would terminate TLS at Nginx with a valid certificate.
- **No process supervision**: Flask runs as a background process (`&`), not a managed systemd service. It will not restart automatically on failure.

---

## Repository Structure

```
.
├── README.md       # This file
└── deploy.sh       # Master deployment script
```

> `app.py` is generated at deploy time and is intentionally excluded from version control.
