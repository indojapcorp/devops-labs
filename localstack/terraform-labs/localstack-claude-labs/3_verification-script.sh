#!/bin/bash

# Verification script for LocalStack EC2 and RDS Lab

echo "============================================="
echo "  LocalStack EC2 and RDS Lab Verification"
echo "============================================="

# Check if LocalStack is running
echo -n "Checking LocalStack status... "
if ! command -v localstack &> /dev/null; then
    echo "FAILED"
    echo "Error: LocalStack is not installed or not in PATH"
    exit 1
fi

if ! curl -s http://localhost:4566/_localstack/health | grep -q "running"; then
    echo "FAILED"
    echo "Error: LocalStack is not running. Start it with 'localstack start'"
    exit 1
fi
echo "OK"

# Check Terraform state
echo -n "Checking Terraform state... "
if [ ! -f "terraform.tfstate" ]; then
    echo "FAILED"
    echo "Error: Terraform state file not found. Run 'terraform apply' first"
    exit 1
fi
echo "OK"

# Verify VPC
echo -n "Verifying VPC... "
VPC_ID=$(aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=main-vpc" \
    --query "Vpcs[0].VpcId" --output text)

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo "FAILED"
    echo "Error: VPC not found"
    exit 1
fi
echo "OK ($VPC_ID)"

# Verify EC2 instance
echo -n "Verifying EC2 instance... "
EC2_ID=$(aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
    --filters "Name=tag:Name,Values=web-server" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ "$EC2_ID" == "None" ] || [ -z "$EC2_ID" ]; then
    echo "FAILED"
    echo "Error: EC2 instance not found or not running"
    exit 1
fi
echo "OK ($EC2_ID)"

# Verify EC2 IAM role
echo -n "Verifying EC2 IAM role... "
EC2_PROFILE=$(aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
    --instance-ids "$EC2_ID" \
    --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text)

if [ "$EC2_PROFILE" == "None" ] || [ -z "$EC2_PROFILE" ]; then
    echo "FAILED"
    echo "Error: EC2 instance has no IAM profile attached"
    exit 1
fi
echo "OK"

# Verify RDS instance
echo -n "Verifying RDS instance... "
RDS_ENDPOINT=$(aws --endpoint-url=http://localhost:4566 rds describe-db-instances \
    --db-instance-identifier main-db \
    --query "DBInstances[0].Endpoint.Address" --output text)

if [ "$RDS_ENDPOINT" == "None" ] || [ -z "$RDS_ENDPOINT" ]; then
    echo "FAILED"
    echo "Error: RDS instance not found or endpoint not available"
    exit 1
fi
echo "OK ($RDS_ENDPOINT)"

# Verify Security Groups
echo -n "Verifying security groups... "
EC2_SG=$(aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups \
    --filters "Name=group-name,Values=ec2-security-group" \
    --query "SecurityGroups[0].GroupId" --output text)

RDS_SG=$(aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups \
    --filters "Name=group-name,Values=rds-security-group" \
    --query "SecurityGroups[0].GroupId" --output text)

if [ "$EC2_SG" == "None" ] || [ -z "$EC2_SG" ] || [ "$RDS_SG" == "None" ] || [ -z "$RDS_SG" ]; then
    echo "FAILED"
    echo "Error: Security groups not properly configured"
    exit 1
fi
echo "OK"

# Check DB secret
echo -n "Verifying DB credentials in Secrets Manager... "
SECRET_ARN=$(aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets \
    --query "SecretList[?Name=='db-credentials'].ARN" --output text)

if [ "$SECRET_ARN" == "None" ] || [ -z "$SECRET_ARN" ]; then
    echo "FAILED"
    echo "Error: DB credentials not found in Secrets Manager"
    exit 1
fi
echo "OK"

# Summary
echo "============================================="
echo "✅ All resources verified successfully!"
echo "EC2 Public IP: $(aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
    --instance-ids "$EC2_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "============================================="
echo "To test the connectivity:"
echo "1. SSH into the EC2 instance (simulated in LocalStack)"
echo "2. Execute the DB connection script at /home/ubuntu/db_connection.sh"
echo "3. Verify the web application at http://<EC2_PUBLIC_IP>"
echo "============================================="
