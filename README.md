# Infrastructure Automation Exam Submission

## Part 1: README Documentation (`README.md`)

### Architecture Overview

This deployment fulfills all evaluation components using a fully automated single-script execution method. The infrastructure leverages Nginx as a unified reverse proxy/ingress controller to manage path-based routing while guaranteeing total isolation for the backend services.

- **Ingress/Proxy Layer:** Nginx listening on Port 80.
- **Application Layer:** Python Flask running on Port 5000 (accessible strictly via `/`).
- **Secrets Management:** HashiCorp Vault running on Port 8200 (accessed programmatically by the app).
- **Telemetry Suite:** Prometheus & Grafana on Port 3000 (accessible strictly via `/dashboard/`).

---

### Deployment Instructions (N = 3 Commands)

To achieve maximum efficiency under the "Automation Excellence" threshold and completely avoid manual text edits or interactive GUI configurations, execute this exact sequence of commands immediately upon gaining SSH access to a clean, stock Ubuntu environment:

```bash
# Command 1: Download the Master Deployment Script
wget -O deploy.sh "[https://gist.githubusercontent.com/davidspringean12/8efedb94d43f2818ee9df3ad7fa6798a/raw/702958742ca51259a4bc19b5b29db429d20c5780/deploy.sh](https://gist.githubusercontent.com/davidspringean12/8efedb94d43f2818ee9df3ad7fa6798a/raw/702958742ca51259a4bc19b5b29db429d20c5780/deploy.sh)"

# Command 2: Elevate Script Permissions
chmod +x deploy.sh

# Command 3: Execute the Automated Build Routine
sudo ./deploy.sh
```
