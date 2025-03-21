#!/bin/bash

# Get the SNS topic ARN from Terraform output
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn)

echo "Publishing test message to SNS topic: $SNS_TOPIC_ARN"

# Publish a test message to the SNS topic
aws --endpoint-url=http://localhost:4566 sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --message '{"event": "user_signup", "data": {"userId": "12345", "email": "test@example.com", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}}' \
  --message-attributes '{"event_type": {"DataType": "String", "StringValue": "user_signup"}}'

echo "Test message published. Check the Lambda logs to see if the message was processed."
echo "To view Lambda logs, run:"
echo "aws --endpoint-url=http://localhost:4566 logs describe-log-streams --log-group-name /aws/lambda/message-processor"
