#!/bin/bash
echo "Cleaning up load balancers..."
for lb in $(aws elb describe-load-balancers --region us-east-1 \
  --query 'LoadBalancerDescriptions[*].LoadBalancerName' \
  --output text 2>/dev/null); do
  aws elb delete-load-balancer --load-balancer-name $lb --region us-east-1
  echo "Deleted LB: $lb"
done

echo "Waiting 60 seconds for LBs to release security groups..."
sleep 60

echo "Cleaning up leftover security groups..."
VPC_ID=$(aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Name,Values=staging-vpc" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
  echo "Found VPC: $VPC_ID"
  for sg in $(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region us-east-1 \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
    --output text 2>/dev/null); do
    echo "Deleting security group: $sg"
    aws ec2 delete-security-group --group-id $sg --region us-east-1 2>/dev/null || true
  done
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
