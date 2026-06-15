# ServiceRadar

ServiceRadar is a real-time service monitoring platform built on AWS. It watches your URLs, detects failures within 90 seconds, and automatically alerts the responsible developer by email — before any customer notices.

No polling dashboards. No manual checks. Just an alert when something breaks.

---

## The idea

You add a service to the database — a name, a URL, and the developer's email. That is it. From that point on, AWS Route53 pings that URL every 30 seconds. Three failures in a row and the whole chain fires:

    Service goes down
          down ~90 seconds later
    CloudWatch detects it
          down
    SNS triggers Lambda
          down
    Developer gets an email
    Incident is saved to the database
    Dashboard updates in real time

No one has to notice. The system notices for you.

---

## What I used

- **Terraform** - every AWS resource is code. Nothing was clicked in the console.
- **EKS + Kubernetes** - the app runs in a real cluster with 2 nodes
- **Helm** - deployments are templated and versioned
- **ArgoCD** - push to GitHub, it deploys itself. That is GitOps.
- **GitHub Actions** - CI builds the image and pushes it to ECR on every merge
- **Aurora MySQL** - stores services and incidents
- **Route53** - does the actual health checking from multiple AWS regions
- **CloudWatch** - watches the health check metrics and fires alarms
- **Lambda** - serverless function that handles the alarm, writes to DB, sends email
- **SNS** - the bridge between CloudWatch and Lambda. Alarm fires, SNS triggers Lambda.
- **SES** - sends the alert email. No confirmation links, no spam filters killing it.
- **API Gateway** - exposes Lambda as a public HTTP endpoint for the dashboard
- **S3** - hosts the ServiceRadar web dashboard as a static website
- **Grafana** - internal dashboard showing cluster metrics and service history

---

## Project layout

    ServiceRadar/
    ├── backend/              # The Python worker that runs in Kubernetes
    │   ├── monitor.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── lambda/               # Triggered by SNS when an alarm fires
    │   └── lambda_function.py
    ├── dashboard/            # S3 static web dashboard
    │   ├── index.html
    │   ├── style.css
    │   └── app.js
    ├── infra/                # All Terraform code
    │   ├── modules/          # vpc, eks, aurora, ecr, lambda
    │   └── environments/
    │       ├── staging/
    │       └── production/
    ├── helm/monitor/         # Kubernetes CronJob definition
    ├── gitops/               # ArgoCD application manifests
    └── .github/workflows/    # CI/CD pipelines

---

## Prerequisites

- AWS CLI configured with admin permissions
- Terraform installed
- kubectl installed
- Helm installed
- ArgoCD CLI installed
- Docker installed

---

## Running it

### Every morning

    ~/final-project/scripts/morning.sh

One command. It takes about 20 minutes and sets up everything:
- Creates 83 AWS resources with Terraform
- Connects kubectl to the EKS cluster
- Installs ArgoCD and connects it to GitHub
- Deploys the app
- Creates the database tables and inserts the services
- Resets alarms so they fire naturally
- Installs Grafana and exposes it
- Deploys the Lambda function
- Uploads the dashboard to S3

### Every evening

    ~/final-project/scripts/evening.sh

Cleans up the load balancers and destroys everything. Running this overnight saves about $7/day.

### Verify everything is destroyed

    aws eks list-clusters --region us-east-1
    aws rds describe-db-clusters --region us-east-1 --query 'DBClusters[*].DBClusterIdentifier'
    aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=staging-vpc" --query 'Vpcs[*].VpcId'
    aws lambda list-functions --region us-east-1 --query 'Functions[?starts_with(FunctionName, `staging`)].FunctionName'

All should return empty [].

---

## Two environments

| | Staging | Production |
|---|---|---|
| Services | test URLs + a broken one | real company services |
| Check frequency | every 10 min | every 30 min |
| Purpose | development + demo | always on |

---

## The demo

1. Open the ServiceRadar dashboard - Google, GitHub, Amazon all healthy.
2. Point at the broken service - already in ALARM.
3. Reset the alarm:

    aws cloudwatch set-alarm-state --alarm-name broken-service-health-staging --state-value OK --state-reason reset --region us-east-1

4. Wait 90 seconds - Route53 detects the failure automatically.
5. An email arrives.
6. Refresh the dashboard - the incident appears in real time.

---

## Cost

About $0.39/hour when running. I destroy it every night.

| Resource | $/hour |
|---|---|
| EKS cluster | $0.10 |
| 2x EC2 t3.medium | $0.08 |
| Aurora MySQL | $0.08 |
| NAT Gateway | $0.05 |
| Load Balancers | $0.05 |
| Everything else | ~$0.03 |

Running 4 hours a day comes out to about $47/month.

---

Built by Ran Dubnikov - DevOps Final Project, 2026
