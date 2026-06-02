# Service Monitor — DevOps Final Project

A real-time service monitoring platform that automatically detects failures and alerts the responsible developer via email.

---

## What it does

- Monitors any number of URLs every 30 seconds using AWS Route53 Health Checks
- Detects DOWN and SLOW services automatically
- Sends email alerts to the responsible developer via AWS SNS
- Saves every incident to Aurora MySQL for history and reporting
- Displays live dashboards in Grafana

---

## Architecture

```
Developer → GitHub → GitHub Actions → ECR → ArgoCD → EKS
                                                  ↑
                                         Terraform built this

EKS runs monitor.py (CronJob every 30 min)
      ↓
monitor.py reads services from Aurora MySQL
      ↓
Registers URLs with Route53
      ↓
Route53 checks each URL every 30 seconds
      ↓
Service DOWN → CloudWatch Alarm fires
      ↓
SNS sends email to developer
Lambda writes incident to Aurora MySQL
```

---

## Technologies

| Category | Technology |
|---|---|
| Cloud | AWS (EKS, Aurora MySQL, ECR, Route53, CloudWatch, SNS, Lambda, S3) |
| Infrastructure | Terraform |
| Container | Docker |
| Orchestration | Kubernetes |
| Packaging | Helm |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana |
| Backend | Python 3.12 |
| Database | Aurora MySQL |

---

## Project Structure

```
final-project/
├── backend/
│   ├── monitor.py           # reads services from DB, registers with Route53
│   ├── schema.sql           # creates database tables
│   ├── Dockerfile           # packages monitor.py into a container
│   └── requirements.txt     # Python dependencies
├── lambda/
│   └── lambda_function.py   # writes incidents to DB when CloudWatch fires
├── infra/
│   ├── modules/
│   │   ├── vpc/             # AWS network
│   │   ├── eks/             # Kubernetes cluster
│   │   ├── aurora/          # MySQL database
│   │   ├── ecr/             # Docker image storage
│   │   └── lambda/          # serverless function
│   └── environments/
│       ├── staging/         # staging infrastructure
│       └── production/      # production infrastructure
├── helm/
│   └── monitor/             # Helm chart for Kubernetes deployment
├── gitops/
│   ├── staging/             # ArgoCD staging config
│   ├── production/          # ArgoCD production config
│   └── monitoring/          # Grafana dashboard config
└── .github/
    └── workflows/
        ├── ci-feature.yml   # lint on feature branch
        ├── ci-master.yml    # build + deploy to staging on merge
        └── ci-release.yml   # deploy to production on version tag
```

---

## How to Run

### 1. Prerequisites
- AWS CLI configured
- Terraform installed
- kubectl installed
- Helm installed

### 2. Create S3 bucket for Terraform state
```bash
aws s3api create-bucket \
  --bucket monitor-terraform-state-randubnikov \
  --region us-east-1
```

### 3. Run Terraform
```bash
cd infra/environments/staging
terraform init
terraform apply
```

### 4. Run schema.sql on Aurora MySQL
```bash
mysql -h YOUR_AURORA_ENDPOINT -u admin -p monitor_db < backend/schema.sql
```

### 5. Add services to monitor
```sql
INSERT INTO services (name, url, dev_name, dev_email)
VALUES ('Payment API', 'https://httpbin.org/status/200', 'John', 'john@gmail.com');
```

### 6. Deploy with Helm
```bash
helm install monitor ./helm/monitor \
  -f helm/monitor/values-staging.yaml \
  --set db.password=YOUR_PASSWORD
```

### 7. Apply ArgoCD config
```bash
kubectl apply -f gitops/staging/monitor.yaml
```

---

## Live Demo

1. Open Grafana dashboard — all services GREEN
2. Add a broken service:
```sql
INSERT INTO services (name, url, dev_name, dev_email)
VALUES ('Demo Service', 'https://httpbin.org/status/503', 'John', 'john@gmail.com');
```
3. Wait 30 seconds — Route53 detects the failure
4. CloudWatch fires → SNS sends email → Lambda saves incident
5. Show email arriving in real time
6. Show Grafana turning RED
7. Show incidents table updated in Aurora MySQL

---

## Cleanup
```bash
cd infra/environments/staging
terraform destroy
```
