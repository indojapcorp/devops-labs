#!/bin/bash
set -e

echo "Starting deployment to local k3s cluster..."

# Create namespace if it doesn't exist
kubectl create namespace ecommerce 2>/dev/null || echo "Namespace already exists"

# Set up MongoDB with persistent volume for local development
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: ecommerce
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: ecommerce
type: Opaque
data:
  root-username: YWRtaW4=  # admin (base64 encoded)
  root-password: cGFzc3dvcmQ=  # password (base64 encoded)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: mongodb
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: root-username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: root-password
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
      volumes:
      - name: mongodb-data
        persistentVolumeClaim:
          claimName: mongodb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: ecommerce
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
EOF

echo "MongoDB deployed, waiting for it to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/mongodb -n ecommerce || echo "MongoDB may not be ready yet, continuing anyway"

# Deploy microservices
for service in auth products orders cart payment notifications; do
  echo "Building and deploying $service service..."
  
  # For local testing, you'd typically build the image directly on the machine
  # Assuming your code is in directories like ./auth-service, ./product-service, etc.
  docker build -t ecommerce/$service-service:latest ./$service-service
  
  # For k3s, you can use the local image without pushing to a registry
  # Create ConfigMap, Deployment and Service for each microservice
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $service-service-config
  namespace: ecommerce
data:
  NODE_ENV: "development"
  PORT: "3000"
  DB_URI: "mongodb://admin:password@mongodb-service:27017/$service?authSource=admin"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service-service
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service-service
  template:
    metadata:
      labels:
        app: $service-service
    spec:
      containers:
      - name: $service-service
        image: ecommerce/$service-service:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        resources:
          limits:
            cpu: "300m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        envFrom:
        - configMapRef:
            name: $service-service-config
---
apiVersion: v1
kind: Service
metadata:
  name: $service-service
  namespace: ecommerce
spec:
  selector:
    app: $service-service
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
EOF
done

# Deploy frontend
echo "Building and deploying frontend..."
docker build -t ecommerce/frontend:latest ./frontend

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: ecommerce
data:
  NODE_ENV: "development"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ecommerce
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
        image: ecommerce/frontend:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        resources:
          limits:
            cpu: "300m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        envFrom:
        - configMapRef:
            name: frontend-config
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: ecommerce
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
EOF

# Create a simple ingress for local access
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api/auth
        pathType: Prefix
        backend:
          service:
            name: auth-service
            port:
              number: 80
      - path: /api/products
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 80
      - path: /api/orders
        pathType: Prefix
        backend:
          service:
            name: orders-service
            port:
              number: 80
      - path: /api/cart
        pathType: Prefix
        backend:
          service:
            name: cart-service
            port:
              number: 80
      - path: /api/payment
        pathType: Prefix
        backend:
          service:
            name: payment-service
            port:
              number: 80
      - path: /api/notifications
        pathType: Prefix
        backend:
          service:
            name: notification-service
            port:
              number: 80
EOF

echo "Deployment completed! Checking status..."

kubectl get pods -n ecommerce
kubectl get services -n ecommerce
kubectl get ingress -n ecommerce

# Get the address where the application is accessible
INGRESS_IP=$(kubectl get ingress ecommerce-ingress -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$INGRESS_IP" ]; then
  INGRESS_IP="localhost"
fi

echo ""
echo "==========================================================="
echo "Your e-commerce application should be available at:"
echo "http://$INGRESS_IP"
echo ""
echo "If using a local k3s installation, you can also access it at:"
echo "http://localhost"
echo "==========================================================="
