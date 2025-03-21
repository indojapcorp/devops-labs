Below is a step-by-step tutorial to learn MLOps on your MacBook, tailored to your setup with LocalStack and a Kubernetes (k3s) cluster running via Multipass. We’ll build a sample Data Science project pipeline—a simple machine learning model to predict house prices—covering all stages from development to production. This will include data ingestion, preprocessing, model training, deployment, monitoring, and CI/CD integration, leveraging your local environment to mimic a real-world MLOps workflow.
Project Overview
Goal: Predict house prices using a regression model.
Tools:
Python (development environment)
Pandas/Scikit-learn (data processing and modeling)
LocalStack (emulate AWS S3 for data storage)
Kubernetes (k3s) (model deployment)
Terraform (infrastructure as code)
FastAPI (model serving API)
Git (version control)
Optional: Prometheus/Grafana (monitoring)
Prerequisites
Installed Tools:
Python 3.11+ (brew install python)
Git (brew install git)
Terraform (brew install terraform)
kubectl (brew install kubectl)
LocalStack (already installed)
k3s cluster in Multipass (already running)
Docker Desktop (brew install --cask docker)
Assumptions:
k3s kubeconfig is at ~/.kube/k3s-config (adjust if different).
LocalStack is running (localstack start -d).
Step-by-Step Tutorial
Step 1: Set Up Project Structure
Create Project Directory:
bash
mkdir mlops-house-price
cd mlops-house-price
Initialize Git:
bash
git init
Project Structure:
bash
mkdir -p src/{data,preprocessing,training,api} infrastructure monitoring
touch src/data/fetch_data.py src/preprocessing/preprocess.py src/training/train.py src/api/app.py
touch infrastructure/main.tf requirements.txt Dockerfile
src/: Python code for development.
infrastructure/: Terraform for deployment.
monitoring/: (Optional) Monitoring setup.
Step 2: Data Ingestion
Use LocalStack’s S3 to store and fetch data.
Create an S3 Bucket:
bash
awslocal s3 mb s3://house-price-data
Fetch Sample Data (src/data/fetch_data.py):
python
import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

def fetch_data():
    # Connect to LocalStack S3
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    # Download sample dataset (e.g., California housing)
    url = "https://raw.githubusercontent.com/ageron/handson-ml2/master/datasets/housing/housing.csv"
    df = pd.read_csv(url)
    # Upload to LocalStack S3
    df.to_csv('housing.csv', index=False)
    s3.upload_file('housing.csv', 'house-price-data', 'raw/housing.csv')
    print("Data uploaded to s3://house-price-data/raw/housing.csv")
    return df

if __name__ == "__main__":
    fetch_data()
Install Dependencies:
bash
echo "pandas boto3 scikit-learn fastapi uvicorn" > requirements.txt
pip install -r requirements.txt
Run Data Fetch:
bash
python src/data/fetch_data.py
Step 3: Data Preprocessing
Clean and preprocess the data.
Preprocessing Script (src/preprocessing/preprocess.py):
python
import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

def preprocess_data():
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    s3.download_file('house-price-data', 'raw/housing.csv', 'housing.csv')
    df = pd.read_csv('housing.csv')
    # Basic preprocessing
    df = df.dropna()  # Drop missing values
    df = df.drop(columns=['ocean_proximity'])  # Simplify for demo
    # Save preprocessed data
    df.to_csv('housing_preprocessed.csv', index=False)
    s3.upload_file('housing_preprocessed.csv', 'house-price-data', 'processed/housing_preprocessed.csv')
    print("Preprocessed data uploaded to s3://house-price-data/processed/housing_preprocessed.csv")
    return df

if __name__ == "__main__":
    preprocess_data()
Run Preprocessing:
bash
python src/preprocessing/preprocess.py
Step 4: Model Training
Train a simple regression model.
Training Script (src/training/train.py):
python
import pandas as pd
import boto3
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
import joblib
from botocore import UNSIGNED
from botocore.client import Config

def train_model():
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    s3.download_file('house-price-data', 'processed/housing_preprocessed.csv', 'housing_preprocessed.csv')
    df = pd.read_csv('housing_preprocessed.csv')
    X = df.drop(columns=['median_house_value'])
    y = df['median_house_value']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = LinearRegression()
    model.fit(X_train, y_train)
    score = model.score(X_test, y_test)
    print(f"Model R^2 Score: {score}")
    # Save model
    joblib.dump(model, 'model.pkl')
    s3.upload_file('model.pkl', 'house-price-data', 'models/model.pkl')
    print("Model uploaded to s3://house-price-data/models/model.pkl")

if __name__ == "__main__":
    train_model()
Run Training:
bash
python src/training/train.py
Step 5: Model Serving (Development)
Serve the model locally with FastAPI.
API Script (src/api/app.py):
python
from fastapi import FastAPI
import joblib
import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

app = FastAPI()
s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
s3.download_file('house-price-data', 'models/model.pkl', 'model.pkl')
model = joblib.load('model.pkl')

@app.post("/predict")
async def predict(data: dict):
    df = pd.DataFrame([data])
    prediction = model.predict(df)[0]
    return {"prediction": float(prediction)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
Test Locally:
bash
python src/api/app.py
In another terminal:
bash
curl -X POST "http://localhost:8000/predict" -H "Content-Type: application/json" -d '{"longitude": -122.23, "latitude": 37.88, "housing_median_age": 41, "total_rooms": 880, "total_bedrooms": 129, "population": 322, "households": 126, "median_income": 8.3252}'
Expected output: {"prediction": <some_value>}
Step 6: Containerize the Model
Build a Docker image for deployment.
Dockerfile:
dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY src/api/app.py .
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
Build and Test Locally:
bash
docker build -t house-price-api:latest .
docker run -p 8000:8000 house-price-api:latest
Test again with the curl command.
Step 7: Deploy to Kubernetes with Terraform
Deploy the API to your k3s cluster.
Terraform Config (infrastructure/main.tf):
hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/k3s-config"
}

resource "kubernetes_namespace" "mlops" {
  metadata {
    name = "mlops"
  }
}

resource "kubernetes_deployment" "house_price_api" {
  metadata {
    name      = "house-price-api"
    namespace = kubernetes_namespace.mlops.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "house-price-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "house-price-api"
        }
      }
      spec {
        container {
          image = "house-price-api:latest"
          name  = "house-price-api"
          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "house_price_api" {
  metadata {
    name      = "house-price-api-service"
    namespace = kubernetes_namespace.mlops.metadata[0].name
  }
  spec {
    selector = {
      app = "house-price-api"
    }
    port {
      port        = 8000
      target_port = 8000
    }
    type = "ClusterIP"
  }
}
Push Image to k3s:
Since k3s runs in Multipass, load the image into the VM:
bash
docker save house-price-api:latest | multipass transfer - k3s-vm:/tmp/house-price-api.tar
multipass exec k3s-vm -- sudo k3s ctr images import /tmp/house-price-api.tar
Deploy:
bash
cd infrastructure
terraform init
terraform apply
Test in Cluster:
bash
kubectl port-forward -n mlops svc/house-price-api-service 8000:8000
Use the same curl command to test.
Step 8: Monitoring (Optional)
Add basic monitoring with Prometheus.
Install Prometheus:
bash
kubectl create namespace monitoring
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
Expose Metrics in API:
Update src/api/app.py to include a /metrics endpoint (requires prometheus-client).
python
from prometheus_client import Counter, generate_latest
app_requests = Counter('app_requests_total', 'Total requests')

@app.get("/metrics")
async def metrics():
    app_requests.inc()
    return generate_latest()
Rebuild and Redeploy:
Add prometheus-client to requirements.txt, rebuild the Docker image, and reapply Terraform.
Step 9: CI/CD (Basic)
Use GitHub Actions for automation (mocked locally).
Push to GitHub:
bash
git add .
git commit -m "Initial MLOps pipeline"
git remote add origin <your-repo-url>
git push origin main
Sample Workflow (.github/workflows/ci.yml):
yaml
name: CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - run: docker build -t house-price-api .
Step 10: Productionize
Scaling: Increase replicas in main.tf.
Persistent Storage: Replace empty_dir with a PVC in Terraform.
CI/CD: Extend the workflow to deploy to k3s.
Cleanup
bash
terraform destroy -auto-approve
multipass stop k3s-vm
localstack stop
Learning Outcomes
Data: Managed with LocalStack S3.
Development: Preprocessing and training locally.
Deployment: Containerized and deployed to k3s.
MLOps: Infrastructure as code, basic monitoring, and CI/CD.
Let me know if you want to dive deeper into any step!