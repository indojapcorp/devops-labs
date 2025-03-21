Let’s create a sample lab to explore container orchestration using Docker and Kubernetes (k3s) on your MacBook Air M1 with Multipass, while integrating LocalStack for cloud simulation and Terraform for infrastructure-as-code. The lab will focus on key concepts like containerization, deployment, scaling, service discovery, configuration management, and cloud integration—all using lightweight images to ensure smooth performance on your setup.
Lab Overview
Goal: Deploy a simple voting application with a frontend, backend, and database, orchestrated by Kubernetes, and integrate an AWS S3 bucket (via LocalStack) for storing votes.
Tools: Docker, k3s (Kubernetes), LocalStack, Terraform.
Key Concepts:
Docker: Containerizing apps with small images (e.g., Alpine-based).
Kubernetes: Pods, Deployments, Services, ConfigMaps, Scaling, Storage.
LocalStack: Simulate AWS S3 for cloud integration.
Terraform: Define Kubernetes resources and LocalStack S3 bucket as code.
Prerequisites
Docker installed and running.
Multipass installed with a k3s cluster (e.g., multipass launch --name k3s --cpus 2 --memory 4G --disk 20G followed by multipass exec k3s -- sudo k3s server &).
kubectl configured to talk to your k3s cluster (copy the kubeconfig from /etc/rancher/k3s/k3s.yaml in the Multipass VM and adjust the server IP).
LocalStack running locally (e.g., localstack start in a terminal).
Terraform installed.
Step 1: Build Lightweight Docker Images
We’ll create a simple voting app with three components:
Frontend: A Python Flask app to vote (using python:3.9-alpine).
Backend: A Python app to process votes (using python:3.9-alpine).
Database: Redis to store votes (using redis:alpine).
Directory Structure
voting-app/
├── frontend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── backend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
└── kubernetes/
    ├── frontend-deployment.yaml
    ├── backend-deployment.yaml
    ├── redis-deployment.yaml
    └── configmap.yaml
└── terraform/
    ├── main.tf
    ├── provider.tf
    └── variables.tf
Frontend (voting-app/frontend/)
Dockerfile:
dockerfile
FROM python:3.9-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
requirements.txt:
flask==2.3.3
requests==2.31.0
app.py:
python
from flask import Flask, request, render_template_string
import requests

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def vote():
    if request.method == 'POST':
        vote = request.form['vote']
        requests.post('http://backend:5001/vote', json={'vote': vote})
    return render_template_string('''
        <form method="POST">
            <button name="vote" value="yes">Yes</button>
            <button name="vote" value="no">No</button>
        </form>
    ''')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
Backend (voting-app/backend/)
Dockerfile:
dockerfile
FROM python:3.9-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5001
CMD ["python", "app.py"]
requirements.txt:
flask==2.3.3
redis==5.0.1
boto3==1.34.0
app.py:
python
from flask import Flask, request
import redis
import boto3
import os

app = Flask(__name__)
r = redis.Redis(host='redis', port=6379, decode_responses=True)
s3 = boto3.client('s3', endpoint_url='http://localhost:4566', aws_access_key_id='test', aws_secret_access_key='test')

@app.route('/vote', methods=['POST'])
def vote():
    vote = request.json['vote']
    r.incr(vote)
    s3.put_object(Bucket='votes-bucket', Key=f'vote-{vote}', Body=vote.encode())
    return 'Vote recorded', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
Build Images
bash
cd voting-app/frontend && docker build -t voting-frontend:latest .
cd ../backend && docker build -t voting-backend:latest .
No need to build Redis—it’s already lightweight as redis:alpine.
Step 2: Kubernetes Manifests
ConfigMap (voting-app/kubernetes/configmap.yaml)
yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  ENVIRONMENT: "dev"
Redis Deployment (voting-app/kubernetes/redis-deployment.yaml)
yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
Backend Deployment (voting-app/kubernetes/backend-deployment.yaml)
yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: voting-backend:latest
        ports:
        - containerPort: 5001
        envFrom:
        - configMapRef:
            name: app-config
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  ports:
  - port: 5001
    targetPort: 5001
  selector:
    app: backend
Frontend Deployment (voting-app/kubernetes/frontend-deployment.yaml)
yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: voting-frontend:latest
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30000
  selector:
    app: frontend
Apply Manifests
bash
kubectl apply -f voting-app/kubernetes/
Step 3: Terraform for Cloud Integration
Terraform Config (voting-app/terraform/)
provider.tf:
hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3 = "http://localhost:4566"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Adjust to your k3s kubeconfig path
}
main.tf:
hcl
resource "aws_s3_bucket" "votes_bucket" {
  bucket = "votes-bucket"
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          image = "voting-backend:latest"
          name  = "backend"
          port {
            container_port = 5001
          }
        }
      }
    }
  }
}
variables.tf:
hcl
variable "kube_config" {
  default = "~/.kube/config"
}
Apply Terraform
bash
cd voting-app/terraform
terraform init
terraform apply
Step 4: Test the Lab
Access the App: Find your Multipass VM IP (multipass list) and visit http://<VM-IP>:30000. Vote “Yes” or “No”.
Check Redis: 
bash
kubectl exec -it $(kubectl get pod -l app=redis -o jsonpath="{.items[0].metadata.name}") -- redis-cli
KEYS *
GET yes
Scale Backend: 
bash
kubectl scale deployment backend --replicas=3
kubectl get pods
Verify S3: 
bash
aws --endpoint-url=http://localhost:4566 s3 ls s3://votes-bucket/
Key Concepts Explored
Docker: Lightweight images (alpine) for resource efficiency.
Kubernetes: 
Pods/Deployments for app deployment.
Services for networking (NodePort, internal discovery).
ConfigMaps for configuration.
Scaling with replicas.
LocalStack: Simulated AWS S3 for cloud integration.
Terraform: Infrastructure-as-code for Kubernetes and cloud resources.
This lab runs efficiently on your MacBook Air M1 and demonstrates container orchestration fundamentals! Let me know if you’d like to tweak anything.



-------------
Alternative: Load Images Directly into k3s (No Docker Hub)
If you’d rather not use Docker Hub, you can transfer the locally built images to your Multipass VM and import them into k3s. Here’s how:
Save Images Locally:
bash
docker save -o voting-frontend.tar voting-frontend:latest
docker save -o voting-backend.tar voting-backend:latest
Transfer to Multipass VM:
bash
multipass transfer voting-frontend.tar k3s:.
multipass transfer voting-backend.tar k3s:.
Load Images into k3s:
bash
multipass exec k3s -- sudo k3s ctr images import voting-frontend.tar
multipass exec k3s -- sudo k3s ctr images import voting-backend.tar
Use Local Images: Keep the manifests as voting-frontend:latest and voting-backend:latest—no changes needed since the images are now in the k3s container runtime.
Updated Workflow
With Docker Hub: Build, tag, push, and update manifests with yourusername/ prefixed images. Then apply manifests or Terraform as before.
Without Docker Hub: Build, save, transfer, and load images into k3s, then use the original manifests.

----------

 localstack start -d\n
 multipass start k3s-vm
 pip install -r requirements.txt
 docker build -t voting-frontend:latest .
 build -t voting-backend:latest .
 docker build -t voting-backend:latest .
 docker tag voting-frontend:latest indojapcorp/voting-frontend:latest\n
 docker push indojapcorp/voting-frontend:latest
 docker tag voting-backend:latest indojapcorp/voting-backend:latest
 docker push indojapcorp/voting-backend:latest

 kubectl apply -f k8s/
 kubectl get pods
 kubectl get pods
 #kubectl delete -f k8s/

 kubectl get deployments
 multipass list
 ./checkredis.sh
 kubectl scale deployment backend --replicas=2
 kubectl get all -o wide\n
 aws --endpoint-url=http://localhost:4566 s3 ls s3://votes-bucket/
 kubectl scale deployment backend --replicas=1
 

 Step 3: Terraform for Cloud Integration

 cd terraform
 tflocal init\n
 tflocal apply\n
 kubectl get all -o wide\n

 aws --endpoint-url=http://localhost:4566 s3 mb s3://votes-bucket\n
 aws --endpoint-url=http://localhost:4566 s3 ls
 aws --endpoint-url=http://localhost:4566 s3 rb s3://votes-bucket\n
 aws --endpoint-url=http://localhost:4566 s3 ls

 TF_LOG=DEBUG tflocal apply > terraform_debug.log 2>&1\n
 tflocal destroy\n
 terraform apply -target=aws_s3_bucket.votes_bucket\n

 tflocal init\n
 tflocal apply\n
