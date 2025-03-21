#!/bin/bash
# scripts/setup.sh

set -e

echo "Setting up ecommerce application..."

# Install dependencies for each service
for service in api-gateway auth products cart orders payment notifications; do
  echo "Installing dependencies for $service service..."
  cd ../services/$service
  npm init -y
  npm install express cors http-proxy-middleware morgan
  
  # Add specific dependencies for each service
  case $service in
    api-gateway)
      npm install http-proxy-middleware
      ;;
    auth)
      npm install jsonwebtoken bcrypt mongoose
      ;;
    products|cart|orders)
      npm install mongoose
      ;;
    payment)
      npm install stripe
      ;;
    notifications)
      npm install nodemailer
      ;;
  esac
  
  # Create basic directory structure
  mkdir -p src config
  #touch src/index.js
  
  echo "Current directory is: $(pwd)"

  cd ../
done

# Initialize client application
#cd client
# Client setup is handled by create-next-app in a separate step

# Verify Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  #exit 1
fi

# Create Docker Compose file
cat > docker-compose-2.yml << EOL
version: '3.8'

services:
  api-gateway:
    build: ./services/api-gateway
    ports:
      - "3000:3000"
    environment:
      - AUTH_SERVICE=http://auth:3001
      - PRODUCTS_SERVICE=http://products:3002
      - CART_SERVICE=http://cart:3003
      - ORDERS_SERVICE=http://orders:3004
      - PAYMENT_SERVICE=http://payment:3005
    depends_on:
      - auth
      - products
      - cart
      - orders
      - payment

  auth:
    build: ./services/auth
    ports:
      - "3001:3001"
    environment:
      - MONGODB_URI=mongodb://auth-db:27017/auth
    depends_on:
      - auth-db

  products:
    build: ./services/products
    ports:
      - "3002:3002"
    environment:
      - MONGODB_URI=mongodb://products-db:27017/products
    depends_on:
      - products-db

  cart:
    build: ./services/cart
    ports:
      - "3003:3003"
    environment:
      - MONGODB_URI=mongodb://cart-db:27017/cart
    depends_on:
      - cart-db

  orders:
    build: ./services/orders
    ports:
      - "3004:3004"
    environment:
      - MONGODB_URI=mongodb://orders-db:27017/orders
    depends_on:
      - orders-db

  payment:
    build: ./services/payment
    ports:
      - "3005:3005"
    environment:
      - STRIPE_API_KEY=your_test_key_here

  notifications:
    build: ./services/notifications
    ports:
      - "3006:3006"

  # Database services
  auth-db:
    image: mongo:6.0-jammy
    volumes:
      - auth-data:/data/db

  products-db:
    image: mongo:6.0-jammy
    volumes:
      - products-data:/data/db

  cart-db:
    image: mongo:6.0-jammy
    volumes:
      - cart-data:/data/db

  orders-db:
    image: mongo:6.0-jammy
    volumes:
      - orders-data:/data/db

  # Frontend
  client:
    build: ./client
    ports:
      - "3080:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:3000/api

volumes:
  auth-data:
  products-data:
  cart-data:
  orders-data:
EOL

echo "Setup complete!"
echo "To build and run the application locally:"
echo "  docker-compose up --build"
echo ""
echo "To deploy to your k3s cluster:"
echo "1. Build and push the Docker images"
echo "2. Apply the Kubernetes manifests: kubectl apply -k k8s/overlays/dev"
