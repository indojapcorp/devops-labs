#!/bin/bash

# Create namespace
kubectl create namespace ecommerce

# Apply MongoDB secrets first
kubectl apply -f mongodb.yaml -n ecommerce

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n ecommerce

# Apply all other resources
kubectl apply -k . -n ecommerce

# Check deployment status
echo "Checking deployment status..."
kubectl get all -n ecommerce

echo "Deployment complete! Access your application at ecommerce.example.com"
