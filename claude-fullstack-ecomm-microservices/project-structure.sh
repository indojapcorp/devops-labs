mkdir -p ecommerce-app/{services/{api-gateway,auth,products,cart,orders,payment,notifications},client,k8s,scripts}
cd ecommerce-app
# Initialize git repository
git init
# Create base files
touch docker-compose.yml .gitignore README.md
# Create k8s manifests directory structure
mkdir -p k8s/{base,overlays/{dev,prod}}
# Create CI/CD pipeline files
mkdir -p .github/workflows
touch .github/workflows/ci.yml
touch .github/workflows/cd.yml
