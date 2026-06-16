# ServiceRadar

ServiceRadar is a real-time service monitoring platform built on AWS. It watches your URLs, detects failures, and automatically alerts the responsible developer by email — before any customer notices.

No polling dashboards. No manual checks. Just an alert when something breaks, and another one when it recovers.

---

## The idea

You add a service to the database — a name, a URL, and the developer's email. That is it. From that point on, AWS Route53 pings that URL every 30 seconds. Three failures in a row and the whole chain fires:

    Service goes down
    Route53 detects it (~90 seconds)
    CloudWatch alarm fires
    SNS triggers Lambda
    Developer gets an email
    Incident is saved to the database
    Dashboard updates in real time
    When service recovers — another email confirms it

No one has to notice. The system notices for you.

---

## What I used

- **Terraform** - every AWS resource is code. Nothing was clicked in the console.
- **EKS + Kubernetes** - the app runs in a real cluster with 2 nodes
- **Helm** - deployments are templated and versioned
- **ArgoCD** - push to GitHub, it deploys itself. That is GitOps.
- **GitHub Actions** - CI builds the image and pushes it to ECR on every merge
- **Aurora MySQL** - stores services and incidents
- **Route53** - health checks from multiple AWS regions, checks actual HTTP response
- **CloudWatch** - watches the health check metrics and fires alarms
- **Lambda** - serverless function that handles the alarm, writes to DB, sends email
- **SQS** - dead letter queue for failed Lambda invocations
- **SNS** - the bridge between CloudWatch and Lambda
- **SES** - sends the alert email
- **API Gateway** - exposes Lambda as a public HTTP endpoint for the dashboard
- **S3** - hosts the ServiceRadar web dashboard as a static website
- **Prometheus + Grafana** - unified dashboard showing both cluster metrics and service health via CloudWatch datasource

---

## Project layout

    ServiceRadar/
    ├── backend/              # Python CronJob — checks URLs, writes incidents on status change
    │   ├── monitor.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── lambda/               # Triggered by SNS when a CloudWatch alarm fires
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
    ├── helm/monitor/         # Kubernetes CronJob Helm chart
    ├── gitops/               # ArgoCD manifests + monitoring config
    │   ├── staging/
    │   └── monitoring/       # Grafana dashboards, datasources, Prometheus values
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
- Creates all AWS resources with Terraform
- Connects kubectl to the EKS cluster
- Installs ArgoCD and connects it to GitHub
- Deploys the app via GitOps
- Creates the database tables and inserts the services
- Resets alarms so they fire naturally
- Installs Prometheus and Grafana with persistence
- Deploys the Lambda function
- Uploads the dashboard to S3

When installing kube-prometheus-stack, pass the values file for persistence:

    helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
      -n monitoring \
      -f ~/final-project/gitops/monitoring/prometheus-stack-values.yaml

### Every evening

    ~/final-project/scripts/evening.sh

Cleans up load balancers (both classic and v2), retries security group deletion automatically, then destroys everything with Terraform.

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

## Alert pipeline

1. Route53 checks each URL every 30 seconds (actual HTTP GET, not just TCP)
2. Three consecutive failures → CloudWatch alarm fires
3. CloudWatch sends to SNS, which triggers Lambda
4. Lambda writes the incident to Aurora and emails the developer
5. When the service recovers, CloudWatch fires an OK action → Lambda sends a recovery email
6. If Lambda fails, the event goes to an SQS dead letter queue for replay

---

## Adding a service to monitor

Add it to `infra/environments/staging/vars.tf`:

```hcl
"my-service" = {
  url  = "my-service.com"
  type = "HTTPS"   # HTTPS (default), HTTP, or TCP
  port = 443       # default 443
  path = "/"       # URL path to check, default "/"
}
```

Then run `terraform apply`. Route53, CloudWatch alarm, and SNS trigger are all created automatically.

---

## Grafana dashboard

Grafana shows a unified view of:
- **Service health** (via CloudWatch datasource): Route53 health check status for each service, Lambda errors, DLQ message count
- **Cluster health** (via Prometheus): Pod CPU/memory, node CPU/memory

The CloudWatch datasource uses the EKS node IAM role — no credentials to manage.

---

## The demo

1. Open the ServiceRadar dashboard - Google, GitHub, Amazon all healthy.
2. Point at the broken service - already in ALARM.
3. Reset the alarm:

    aws cloudwatch set-alarm-state --alarm-name broken-service-health-staging --state-value OK --state-reason reset --region us-east-1

4. Wait ~3-4 minutes - Route53 detects the failure, CloudWatch alarm fires.
5. An alert email arrives automatically.
6. Refresh the dashboard - the incident appears in real time.
7. Reset the alarm again to OK and wait - a recovery email arrives confirming the service is back up.

---

## Cost

About $0.39/hour when running. Destroyed every night.

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

Built by Ran Dubnikov — DevOps Final Project, 2026
