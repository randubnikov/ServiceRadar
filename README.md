# Service Monitor

A DevOps final project — a monitoring system that watches your services and alerts the right developer when something breaks.

---


I wanted to build something that actually solves a real problem. Instead of a todo app or a blog, I built a tool that continuously checks if your services are alive and sends an email to whoever owns that service the moment something goes wrong.

The whole thing runs on AWS and Kubernetes — no manual intervention needed.

---

## How it works

You register a service (a URL + a developer's email) in the database. From that point on, AWS Route53 checks that URL every 30 seconds. If it fails 3 times in a row, CloudWatch fires an alarm, SNS sends an email to the developer, and a Lambda function saves the incident to the database.

```
Register service in DB
      ↓
Route53 checks URL every 30s
      ↓
Service goes DOWN
      ↓
Email → developer
Incident → saved to DB
Dashboard → turns red
```

---

## Stack

- **AWS** — EKS, Aurora MySQL, ECR, Route53, CloudWatch, SNS, Lambda, S3
- **Terraform** — builds all infrastructure
- **Docker + Kubernetes** — runs the app
- **Helm** — manages deployments
- **ArgoCD** — GitOps, auto-deploys on every push
- **GitHub Actions** — CI/CD pipeline
- **Prometheus + Grafana** — monitoring dashboards
- **Python 3.12** — backend worker script

---

## Project structure

```
final-project/
├── backend/          # Python worker + SQL schema + Dockerfile
├── lambda/           # AWS Lambda function for incident tracking
├── infra/            # Terraform modules and environments
├── helm/             # Kubernetes deployment configs
├── gitops/           # ArgoCD configs for staging and production
└── .github/          # GitHub Actions workflows
```

---

## Running it

### Prerequisites
- AWS CLI configured
- Terraform, kubectl, Helm installed

### Steps

```bash
# 1. Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket monitor-terraform-state-randubnikov \
  --region us-east-1

# 2. Run Terraform
cd infra/environments/staging
terraform init
terraform apply

# 3. Set up the database
mysql -h YOUR_AURORA_ENDPOINT -u admin -p monitor_db < backend/schema.sql

# 4. Add a service to monitor
INSERT INTO services (name, url, dev_name, dev_email)
VALUES ('Payment API', 'https://httpbin.org/status/200', 'John', 'john@gmail.com');

# 5. Deploy with Helm
helm install monitor ./helm/monitor \
  -f helm/monitor/values-staging.yaml \
  --set db.password=YOUR_PASSWORD

# 6. Apply ArgoCD
kubectl apply -f gitops/staging/monitor.yaml
```

---

## Demo

The demo is simple but effective:

1. Show Grafana — all services green
2. Add a broken URL to the database
3. Wait 30 seconds
4. Email arrives live
5. Grafana turns red
6. Incidents table shows the new entry

```sql
-- Add a broken service for demo
INSERT INTO services (name, url, dev_name, dev_email)
VALUES ('Demo Service', 'https://httpbin.org/status/503', 'John', 'john@gmail.com');
```

---

## Cleanup

```bash
cd infra/environments/staging
terraform destroy
```
