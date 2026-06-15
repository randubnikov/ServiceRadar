# ServiceRadar — DevOps Final Project

## What this project is
Real-time service monitoring platform built on AWS.
Watches URLs every 30 seconds, detects failures within 90 seconds,
and automatically emails the responsible developer.

## Repository
https://github.com/randubnikov/ServiceRadar

## Full Stack
- Terraform (83 resources) — all infrastructure as code
- EKS 1.35 (2x t3.medium nodes) — Kubernetes cluster
- Helm — package manager for K8s
- ArgoCD — GitOps, auto-deploys on git push
- GitHub Actions — CI/CD pipeline
- Aurora MySQL 8.0 — stores services and incidents
- Route53 — health checks every 30 seconds
- CloudWatch — alarms when health check fails
- SNS — triggers Lambda when alarm fires
- Lambda (Python 3.12) — writes incident to DB, sends email
- SES — sends alert emails
- API Gateway — public HTTP endpoint for dashboard
- S3 — hosts web dashboard
- Grafana — metrics dashboard
- Prometheus — cluster metrics

## AWS Account
- Account ID: 708325790793
- Region: us-east-1
- IAM user: localadmin

## Key Endpoints (change after every morning script)
- Aurora: staging-monitor-db.cluster-ccnysauq6hoy.us-east-1.rds.amazonaws.com
- ECR: 708325790793.dkr.ecr.us-east-1.amazonaws.com/staging-monitor
- SNS: arn:aws:sns:us-east-1:708325790793:staging-monitor-alerts
- API Gateway: https://no16v2fzog.execute-api.us-east-1.amazonaws.com
- Dashboard: http://serviceradar-dashboard-staging.s3-website-us-east-1.amazonaws.com

## Credentials
- DB: admin / Tuco2022Aa → monitor_db
- Grafana: admin / Grafana2026
- ArgoCD: admin / gaC4f93o0l786Tmv

## Repository Structure
final-project/
├── backend/monitor.py           # Python CronJob — reads services from DB
├── lambda/lambda_function.py    # SNS alarm handler + API Gateway handler
├── dashboard/                   # S3 static web dashboard
│   ├── index.html
│   ├── style.css
│   └── app.js                   # API_URL = REPLACE_WITH_API_URL placeholder
├── infra/
│   ├── modules/vpc/ eks/ aurora/ ecr/ lambda/
│   └── environments/staging/    # main.tf, vars.tf, providers.tf, outputs.tf
├── helm/monitor/                # Kubernetes CronJob Helm chart
├── gitops/staging/monitor.yaml  # ArgoCD Application manifest
└── scripts/
    ├── morning.sh               # Full automation (gitignored)
    └── evening.sh               # Cleanup + terraform destroy

## DB Schema
services (id, name, url, dev_name, dev_email, created_at)
incidents (id, service_id, status, error_message, created_at)

## Monitored Services
- Google     → www.google.com
- GitHub     → www.github.com
- Amazon     → www.amazon.com
- Broken     → this-does-not-exist.com (always DOWN for demo)

## Morning Script does automatically
1. terraform apply (83 resources)
2. kubectl connect to EKS
3. Grant cluster access
4. Create namespaces (staging, production, monitoring)
5. Install ArgoCD + expose UI
6. Connect ArgoCD to GitHub
7. Deploy staging app via ArgoCD
8. Create DB tables + insert services
9. Reset CloudWatch alarms
10. Install Prometheus + Grafana
11. Deploy Lambda function
12. Upload dashboard to S3

## Evening Script does automatically
1. Delete Load Balancers
2. Wait 60 seconds
3. Delete leftover k8s-elb-* security groups
4. Delete ECR images
5. terraform destroy

## Common Issues and Fixes
- VPC stuck destroying: k8s-elb-* security groups still exist, delete manually
- DB init fails: run kubectl run db-init manually with mysql:8 image
- Lambda routing: uses event.get('rawPath') or event.get('path', '/')
- Dashboard empty: check API_URL was replaced in app.js before S3 upload
- ArgoCD DNS: wait 120 seconds after LoadBalancer creation before login

## Lambda Function Logic
lambda_handler routes by event type:
- 'path' in event → handle_api() → queries Aurora, returns JSON
- 'Records' in event → handle_alarm() → writes incident, sends SES email

## Cost
~$0.39/hour running
~$47/month at 4 hours/day
Destroy every night

## Presentation Demo Flow
1. Open ServiceRadar dashboard — show 4 services
2. Show broken-service already in ALARM
3. Reset alarm: aws cloudwatch set-alarm-state --alarm-name broken-service-health-staging --state-value OK --state-reason reset --region us-east-1
4. Wait 90 seconds
5. Email arrives automatically
6. Refresh dashboard — incident appears in incidents tab
