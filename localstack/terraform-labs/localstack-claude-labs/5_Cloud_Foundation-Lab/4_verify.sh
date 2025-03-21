# List created EC2 instances
aws --endpoint-url=http://localhost:4566 ec2 describe-instances

# List S3 buckets and objects
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3 ls s3://$BUCKET_NAME

# List IAM roles
aws --endpoint-url=http://localhost:4566 iam list-roles