# Create the CloudFormation stack using LocalStack
aws --endpoint-url=http://localhost:4566 cloudformation create-stack \
  --stack-name webapp-stack \
  --template-body file://webapp-stack.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=DevEnv