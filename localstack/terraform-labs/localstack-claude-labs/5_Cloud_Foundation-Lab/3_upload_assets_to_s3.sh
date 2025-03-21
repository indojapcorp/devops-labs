# Get the bucket name from stack outputs
BUCKET_NAME=$(aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name webapp-stack \
  --query "Stacks[0].Outputs[?ExportName=='DevEnv-WEBSITE-BUCKET'].OutputValue" \
  --output text)

# Upload assets to the S3 bucket
aws --endpoint-url=http://localhost:4566 s3 cp ./assets/sample.html s3://$BUCKET_NAME/