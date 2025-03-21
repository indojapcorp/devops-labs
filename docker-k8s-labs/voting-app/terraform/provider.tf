terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true  # Add this line to fix the error

  endpoints {
    s3 = "http://localhost:4566"  # LocalStack endpoint
  }
}

provider "kubernetes" {
  config_path = "~/mydev/tuts/cloudtuts/k8sshared/k3s.yaml" # Adjust to your k3s kubeconfig path
}