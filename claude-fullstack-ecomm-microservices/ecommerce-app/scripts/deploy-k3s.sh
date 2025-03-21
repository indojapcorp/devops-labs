#!/bin/bash
# scripts/deploy-k3s.sh

set -e

REGISTRY="localhost:5000"

# Check if k3s is running
if ! kubectl get nodes > /dev/null 2>&1; then
  echo "k3s cluster not accessible. Please ensure your cluster is running."
  exit 1
fi

# Start local registry if not running
if ! docker ps | grep -q "registry:2"; then
  echo "Starting local Docker registry"
  docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi

# Build and push images to local registry
echo "Building and pushing Docker images..."

for service in services/*/; do
  service_name=$(basename $service)
  echo "Processing $service_name..."
  
  # Build image
  docker build -t ${REGISTRY}/ecommerce-${service_name}:latest $service
  
  # Push to local registry
  docker push ${REGISTRY}/ecommerce-${service_name}:latest
done

# Build and push client
echo "Building and pushing client..."
docker build -t ${REGISTRY}/ecommerce-client:latest client/
docker push ${REGISTRY}/ecommerce-client:latest

# Update Kustomize configs with local registry
mkdir -p k8s/overlays/local

# Create local overlay
cat > k8s/overlays/local/kustomization.yaml << EOL
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

nameSuffix: -local

images:
  - name: ghcr.io/username/ecommerce-api-gateway
    newName: ${REGISTRY}/ecommerce-api-gateway
    newTag: latest
  - name: ghcr.io/username/ecommerce-auth
    newName: ${REGISTRY}/ecommerce-auth
    newTag: latest
  - name: ghcr.io/username/ecommerce-products
    newName: ${REGISTRY}/ecommerce-products
    newTag: latest
  - name: ghcr.io/username/ecommerce-cart
    newName: ${REGISTRY}/ecommerce-cart
    newTag: latest
  - name: ghcr.io/username/ecommerce-orders
    newName: ${REGISTRY}/ecommerce-orders
    newTag: latest
  - name: ghcr.io/username/ecommerce-payment
    newName: ${REGISTRY}/ecommerce-payment
    newTag: latest
  - name: ghcr.io/username/ecommerce-notifications
    newName: ${REGISTRY}/ecommerce-notifications
    newTag: latest
  - name: ghcr.io/username/ecommerce-client
    newName: ${REGISTRY}/ecommerce-client
    newTag: latest
EOL

# Create namespace if it doesn't exist
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -

# Apply Kubernetes manifests
echo "Deploying to k3s cluster..."
kubectl apply -k k8s/overlays/local

echo "Deployment complete!"
echo "Wait for pods to become ready with: kubectl get pods -n ecommerce -w"
echo "Access the application at: http://ecommerce.local"
echo "Don't forget to add 'ecommerce.local' to your /etc/hosts file pointing to your cluster IP"