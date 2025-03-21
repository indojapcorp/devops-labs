#!/bin/bash

# Set LocalStack endpoint
export AWS_ENDPOINT_URL="http://localhost:4566"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

# Function to print section headers
print_header() {
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Get VPC information
print_header "VPC Information"
aws --endpoint-url=$AWS_ENDPOINT_URL ec2 describe-vpcs --filters "Name=tag:Name,Values=web-app-vpc" --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock,State:State}'

# Get Subnet information
print_header "Subnet Information"
aws --endpoint-url=$AWS_ENDPOINT_URL ec2 describe-subnets --filters "Name=tag:Name,Values=web-app-subnet" --query 'Subnets[*].{SubnetId:SubnetId,VpcId:VpcId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone}'

# Get Security Group information
print_header "Security Group Information"
aws --endpoint-url=$AWS_ENDPOINT_URL ec2 describe-security-groups --filters "Name=tag:Name,Values=web-app-sg" --query 'SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,VpcId:VpcId}'

# Get EC2 Instance information
print_header "EC2 Instance Information"
aws --endpoint-url=$AWS_ENDPOINT_URL ec2 describe-instances --filters "Name=tag:Name,Values=web-server" --query 'Reservations[*].Instances[*].{InstanceId:InstanceId,InstanceType:InstanceType,State:State.Name,PrivateIpAddress:PrivateIpAddress}'

# Get S3 Bucket information
print_header "S3 Bucket Information"
aws --endpoint-url=$AWS_ENDPOINT_URL s3api list-buckets --query 'Buckets[?Name==`web-app-content-bucket`]'

# List S3 Bucket contents
print_header "S3 Bucket Contents"
aws --endpoint-url=$AWS_ENDPOINT_URL s3 ls s3://web-app-content-bucket

# Get Route53 Zone information
print_header "Route53 Zone Information"
aws --endpoint-url=$AWS_ENDPOINT_URL route53 list-hosted-zones --query 'HostedZones[?Name==`webapp.local.`]'

# Get Route53 Record information
print_header "Route53 Record Information"
ZONE_ID=$(aws --endpoint-url=$AWS_ENDPOINT_URL route53 list-hosted-zones --query 'HostedZones[?Name==`webapp.local.`].Id' --output text | cut -d'/' -f3)
if [ ! -z "$ZONE_ID" ]; then
    aws --endpoint-url=$AWS_ENDPOINT_URL route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query 'ResourceRecordSets[?Name==`app.webapp.local.`]'
fi

# Get IAM Role information
print_header "IAM Role Information"
aws --endpoint-url=$AWS_ENDPOINT_URL iam get-role --role-name web-app-role --query 'Role.{RoleName:RoleName,RoleId:RoleId,Arn:Arn}'

# Get IAM Policy information
print_header "IAM Policy Information"
aws --endpoint-url=$AWS_ENDPOINT_URL iam list-policies --scope Local --query 'Policies[?PolicyName==`s3-access-policy`]'

# Test S3 bucket access
print_header "Testing S3 Bucket Access"
aws --endpoint-url=$AWS_ENDPOINT_URL s3 cp s3://web-app-content-bucket/index.html /tmp/index.html
echo "Content of index.html:"
cat /tmp/index.html | head -n 10
echo "..."

print_header "Testing Complete"
echo "If all sections above show data, your infrastructure is properly set up!"
