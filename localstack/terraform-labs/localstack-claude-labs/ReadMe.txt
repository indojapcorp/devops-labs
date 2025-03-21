localstack webapp

localstack is installed on laptop.
Create a lab on localstack using terraform for Simple Web Application Architecture:
* Services involved: EC2, S3, Route 53, IAM.
* Goal: Set up a simple web application with EC2 instances serving static content, backed by an S3 bucket for storing files. Use IAM roles and policies to restrict access.
* Learning objectives: Practice EC2 instance management, S3 bucket permissions, DNS management with Route 53, and IAM.
also write the code to output/test created infra/service related queries like ids etc

# Start LocalStack with required services
localstack start -d

# Initialize Terraform
terraform init

# Apply the configuration
terraform apply -auto-approve

# Make the script executable
chmod +x test-script.sh

# Run the test script
./test-script.sh

aws --endpoint-url=http://localhost:4566 s3 cp s3://web-app-content-bucket/index.html ./

terraform destroy -auto-approve




-----------
serverless lab



localstack is installed on laptop. 
Create a lab on localstack using terraform for Serverless Architecture with Lambda & API Gateway:
* Services involved: Lambda, API Gateway, IAM, S3.
* Goal: Create a simple serverless API using API Gateway that triggers a Lambda function to store data in an S3 bucket.
* Learning objectives: Learn Lambda invocation via API Gateway, API Gateway security (IAM roles), and event-driven architecture.


Test


curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"This is a test item"}' \
  http://localhost:4566/restapis/{rest-api-id}/dev/_user_request_/items

api_url = "https://my9z9vspyw.execute-api.us-east-1.amazonaws.com/dev/items"
rest_api_id = "my9z9vspyw"


curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"This is a test item"}' \
  http://localhost:4566/restapis/my9z9vspyw/dev/_user_request_/items


Verify Data Storage:

aws --endpoint-url=http://localhost:4566 s3 ls s3://serverless-demo-bucket/items/


----------

4.
event-driven architecture with SNS, SQS, and Lambda on LocalStack. This will help you understand how these services work together in an event-driven system.
Event-Driven Architecture with SNS, SQS, and Lambda on LocalStackClick


I'll create a comprehensive lab using Terraform to set up an event-driven architecture with SNS, SQS, and Lambda on LocalStack. This will help you understand how these services work together in an event-driven system.
Event-Driven Architecture with SNS, SQS, and Lambda on LocalStackClick to open codeTap to open
Now you'll need to create the Lambda function code that will be processed:
Lambda Function for Message ProcessingClick to open codeTap to open
Let's also create a simple script to zip the Lambda function for deployment:
Script to prepare Lambda ZIP fileClick to open codeTap to open
Finally, let's create a test script to publish a message to the SNS topic:
Test Script to Publish Messages to SNSClick to open codeTap to open
How to Run the Lab
Here are the steps to set up and run the lab:

Ensure LocalStack is running:
bashCopylocalstack start

Prepare the Lambda function:
bashCopychmod +x prepare-lambda-zip.sh
./prepare-lambda-zip.sh

Apply the Terraform configuration:
bashCopyterraform init
terraform apply -auto-approve

Test the setup by publishing a message:
bashCopychmod +x test-sns-publish.sh
./test-sns-publish.sh


What's Happening in this Architecture

SNS Topic: Acts as a publisher for events/notifications.
SQS Queue: Receives and buffers messages from SNS, providing durability and reliability.
Dead Letter Queue (DLQ): Captures messages that fail processing after multiple attempts.
Lambda Function: Triggered when messages arrive in the SQS queue, processes the messages.
IAM Roles & Policies: Provide necessary permissions for services to interact.

Learning Points

Decoupling: SNS and SQS decouple the components, making the system more resilient.
Fan-out Pattern: SNS can publish to multiple subscribers (we have one SQS queue here but could add more).
Buffering: SQS queues messages, ensuring no loss if Lambda is temporarily unavailable.
Error Handling: The DLQ captures failed processing attempts.
Event-Driven Processing: Lambda only runs when there are messages to process.

Additional Exploration Ideas

Add multiple SQS queues subscribed to the same SNS topic
Implement message filtering based on SNS message attributes
Create different Lambda functions for different message types
Add CloudWatch metrics and alarms (if supported by your LocalStack setup)

This lab gives you hands-on experience with the fundamental building blocks of event-driven architectures in AWS, all running locally on your machine!


-------------


5 Cloud Formation lab:


localstack is installed on laptop. Create a lab on localstack for Infrastructure as Code with CloudFormation:
* Services involved: CloudFormation, EC2, S3, IAM, VPC.
* Goal: Write a CloudFormation template to provision a web application stack, including EC2, S3, VPC, and IAM roles.
* Learning objectives: Learn how to define infrastructure in code, deploy using CloudFormation, and manage infrastructure.
Edit
I'll create a comprehensive lab for Infrastructure as Code using CloudFormation with LocalStack. This lab will walk you through creating and deploying a web application stack with multiple AWS services.

Web Application Stack CloudFormation Template
Click to open code
LocalStack CloudFormation Lab: Infrastructure as Code
Lab Setup
Prerequisites:
LocalStack installed on your laptop
AWS CLI configured to work with LocalStack
Basic understanding of AWS services
Start LocalStack:
bash

Copy
# Start LocalStack with required services
localstack start
Lab Steps
Step 1: Create a Working Directory
bash

Copy
mkdir -p cfn-lab/assets
cd cfn-lab
Step 2: Save the CloudFormation Template
Save the provided YAML template to a file named webapp-stack.yaml.
Step 3: Create Sample Web Content
Create a simple HTML file in the assets directory for later upload to S3:
bash

Copy
echo "<html><body><h1>Sample Web Asset</h1><p>This file is served from S3</p></body></html>" > assets/sample.html
Step 4: Deploy the CloudFormation Stack
bash

Copy
# Create the CloudFormation stack using LocalStack
aws --endpoint-url=http://localhost:4566 cloudformation create-stack \
  --stack-name webapp-stack \
  --template-body file://webapp-stack.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=DevEnv
Step 5: Monitor Stack Creation
bash

Copy
# Check stack creation status
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name webapp-stack
Step 6: Upload Assets to the S3 Bucket
Once the stack is created, get the bucket name and upload assets:
bash

Copy
# Get the bucket name from stack outputs
BUCKET_NAME=$(aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name webapp-stack \
  --query "Stacks[0].Outputs[?ExportName=='DevEnv-WEBSITE-BUCKET'].OutputValue" \
  --output text)

# Upload assets to the S3 bucket
aws --endpoint-url=http://localhost:4566 s3 cp ./assets/sample.html s3://$BUCKET_NAME/
Step 7: Verify Resources
bash

Copy
# List created EC2 instances
aws --endpoint-url=http://localhost:4566 ec2 describe-instances

# List S3 buckets and objects
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3 ls s3://$BUCKET_NAME

# List IAM roles
aws --endpoint-url=http://localhost:4566 iam list-roles
Lab Exercises
Modify the Template:
Try adding additional EC2 instances
Add an Elastic Load Balancer to distribute traffic
Create an Auto Scaling Group for the web servers
Update the Stack:
bash

Copy
aws --endpoint-url=http://localhost:4566 cloudformation update-stack \
  --stack-name webapp-stack \
  --template-body file://webapp-stack-modified.yaml
Delete the Stack:
bash

Copy
aws --endpoint-url=http://localhost:4566 cloudformation delete-stack \
  --stack-name webapp-stack
Learning Points
Infrastructure as Code Benefits:
Version control for infrastructure
Repeatable deployments
Consistency across environments
Self-documenting infrastructure
CloudFormation Concepts:
Templates and stacks
Resources and their dependencies
Parameters for customization
Outputs for cross-stack references
AWS Services Integration:
How different AWS services work together
Role-based access between services
Network configuration for secure deployments
Would you like me to explain any specific part of the template or lab steps in more detail?





3. Identify the Stack Name
You need to know the stack name of the infrastructure you deployed with CloudFormation. If you don't remember the stack name, you can list the existing stacks in LocalStack:

bash
Copy
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks
This command will return a list of all the stacks you have created. Find the StackName of the stack you want to delete.

4. Delete the CloudFormation Stack
Once you have the StackName, you can use the delete-stack command to undeploy the stack:

bash
Copy
aws --endpoint-url=http://localhost:4566 cloudformation delete-stack --stack-name <your-stack-name>
Replace <your-stack-name> with the actual name of your CloudFormation stack.

This will initiate the deletion of the stack and all resources that were provisioned under that stack. LocalStack will simulate the deletion of the resources.

5. Verify Deletion
After you run the delete-stack command, you can verify that the stack has been deleted by describing the stacks again:

bash
Copy
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks

-----------