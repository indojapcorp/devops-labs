provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"  
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
  }
}

# Create an IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })
}

# Attach policies to the IAM role for CloudWatch and CloudTrail access
resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an IAM instance profile to associate with the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-monitoring-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Create an EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Use a valid AMI for LocalStack
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name  # Use the instance profile here

  tags = {
    Name = "WebServer"
  }

  # CloudWatch Logs configuration
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y awslogs
              service awslogs start
              EOF
}

/*
# Set up CloudTrail to capture API calls
resource "aws_cloudtrail" "main" {
  name                          = "cloudtrail-example"
  s3_bucket_name                = "cloudtrail-logs"  # LocalStack mock S3 bucket
  include_global_service_events = true
  is_multi_region_trail         = false
}
*/

# Create CloudWatch Log group for EC2 instance logs
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name = "/aws/ec2/web_server"
}

# Set up CloudWatch Alarm for EC2 instance CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-utilization-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Trigger when CPU utilization exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.web_server.id
  }

  actions_enabled = false
}

# Create CloudWatch Dashboard for visualization
resource "aws_cloudwatch_dashboard" "ec2_dashboard" {
  dashboard_name = "EC2_Monitoring_Dashboard"
  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type" = "metric",
        "x" = 0,
        "y" = 0,
        "width" = 24,
        "height" = 12,
        "properties" = {
          "metrics" = [
            [ "AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web_server.id ]
          ],
          "title" = "EC2 CPU Utilization"
        }
      },
      {
        "type" = "log",
        "x" = 0,
        "y" = 12,
        "width" = 24,
        "height" = 12,
        "properties" = {
          "logGroupName" = aws_cloudwatch_log_group.ec2_logs.name,
          "title" = "EC2 Logs"
        }
      }
    ]
  })
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}
/*
output "cloudtrail_id" {
  description = "The ID of the CloudTrail"
  value       = aws_cloudtrail.main.id
}
*/
output "cloudwatch_dashboard" {
  description = "CloudWatch Dashboard URL"
  value       = "http://localhost:4566/_localstack/cloudwatch/dashboards/${aws_cloudwatch_dashboard.ec2_dashboard.dashboard_name}"
}
