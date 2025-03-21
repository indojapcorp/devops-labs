# main.tf - Event-Driven Architecture with SNS, SQS, and Lambda

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # LocalStack endpoint configuration
  endpoints {
    sns   = "http://localhost:4566"
    sqs   = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam   = "http://localhost:4566"
  }
}

# Create an SNS topic
resource "aws_sns_topic" "notification_topic" {
  name = "notification-topic"
}

# Create an SQS queue
resource "aws_sqs_queue" "notification_queue" {
  name                      = "notification-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400  # 1 day
  receive_wait_time_seconds = 10     # Enable long polling
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}

# Create a Dead Letter Queue for handling failed messages
resource "aws_sqs_queue" "dead_letter_queue" {
  name = "notification-dlq"
  message_retention_seconds = 1209600  # 14 days
}

# Subscribe the SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.notification_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_queue.arn
}

# Create a policy to allow the SNS topic to send messages to the SQS queue
resource "aws_sqs_queue_policy" "notification_queue_policy" {
  queue_url = aws_sqs_queue.notification_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.notification_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.notification_topic.arn
          }
        }
      }
    ]
  })
}

# Create Lambda function for processing messages
resource "aws_lambda_function" "message_processor" {
  filename      = "lambda_function.zip"
  function_name = "message-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 10

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]
}

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the Lambda role
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_execution_policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.notification_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Create the event source mapping to trigger Lambda from SQS
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.notification_queue.arn
  function_name    = aws_lambda_function.message_processor.function_name
  batch_size       = 10
}

# Output important resources for reference
output "sns_topic_arn" {
  value = aws_sns_topic.notification_topic.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.notification_queue.id
}

output "lambda_function_name" {
  value = aws_lambda_function.message_processor.function_name
}
