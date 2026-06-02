#!/bin/bash
echo "Cleaning up load balancers..."
for lb in $(aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[*].LoadBalancerName' --output text 2>/dev/null); do
  aws elb delete-load-balancer --load-balancer-name $lb --region us-east-1
  echo "Deleted LB: $lb"
done

echo "Cleaning up leftover security groups..."
VPC_ID=$(aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Project,Values=monitor" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
  for sg in $(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region us-east-1 \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
    --output text 2>/dev/null); do
    aws ec2 delete-security-group --group-id $sg --region us-east-1 2>/dev/null
    echo "Deleted SG: $sg"
  done
fi

echo "Waiting 30 seconds..."
sleep 30

echo "Destroying infrastructure..."
cd ~/final-project/infra/environments/staging
terraform destroy -auto-approve

echo "Done! Everything destroyed. Sleep well"
