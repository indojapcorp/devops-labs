# Check stack creation status
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name webapp-stack