#!/bin/bash

echo "Cleaning up classic load balancers..."
for lb in $(aws elb describe-load-balancers --region us-east-1 \
  --query 'LoadBalancerDescriptions[*].LoadBalancerName' \
  --output text 2>/dev/null); do
  aws elb delete-load-balancer --load-balancer-name $lb --region us-east-1
  echo "Deleted classic LB: $lb"
done

echo "Cleaning up v2 load balancers (ALB/NLB)..."
for arn in $(aws elbv2 describe-load-balancers --region us-east-1 \
  --query 'LoadBalancers[*].LoadBalancerArn' \
  --output text 2>/dev/null); do
  aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --region us-east-1
  echo "Deleted v2 LB: $arn"
done

echo "Waiting 60 seconds for LBs to release security groups..."
sleep 60

echo "Cleaning up leftover security groups..."
VPC_ID=$(aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Name,Values=staging-vpc" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
  VPC_ID=$(aws ec2 describe-vpcs --region us-east-1 \
    --filters "Name=tag:Project,Values=monitor" \
    --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
fi

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  echo "Found VPC: $VPC_ID"
  for attempt in 1 2 3; do
    FAILED=0
    for sg in $(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --region us-east-1 \
      --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
      --output text 2>/dev/null); do
      aws ec2 delete-security-group --group-id "$sg" --region us-east-1 2>/dev/null \
        && echo "Deleted SG: $sg" \
        || { echo "SG $sg still in use, will retry"; FAILED=1; }
    done
    [ $FAILED -eq 0 ] && break
    echo "Attempt $attempt/3 — waiting 30s before retry..."
    sleep 30
  done
else
  echo "No VPC found - skipping SG cleanup"
fi

echo "Cleaning up ECR images..."
aws ecr batch-delete-image \
  --repository-name staging-monitor \
  --image-ids "$(aws ecr list-images --repository-name staging-monitor \
  --region us-east-1 \
  --query 'imageIds[*]' \
  --output json)" \
  --region us-east-1 2>/dev/null || true

echo "Destroying infrastructure..."
cd ~/final-project/infra/environments/staging
terraform destroy -auto-approve

echo "Done! Everything destroyed."
