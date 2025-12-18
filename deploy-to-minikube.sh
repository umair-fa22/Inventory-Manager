#!/bin/bash
set -e

echo "======================================"
echo "Deploying Inventory Manager to Minikube"
echo "======================================"

# Step 1: Set docker env to use Minikube's Docker daemon
echo ""
echo "Step 1: Setting up Docker environment for Minikube..."
eval $(minikube docker-env)

# Step 2: Build Docker image inside Minikube
echo ""
echo "Step 2: Building Docker image inside Minikube..."
docker build -t inventory-manager:latest .

# Step 3: Create namespace
echo ""
echo "Step 3: Creating namespace..."
kubectl apply -f k8s/namespace-prod.yaml

# Step 4: Create secrets
echo ""
echo "Step 4: Creating secrets..."
kubectl create secret generic inventory-secrets \
  --namespace=inventory-prod \
  --from-literal=mongo-username=admin \
  --from-literal=mongo-password=secure-mongo-password-123 \
  --from-literal=redis-password=secure-redis-password-123 \
  --dry-run=client -o yaml | kubectl apply -f -

# Step 5: Create ConfigMap
echo ""
echo "Step 5: Creating ConfigMap..."
kubectl apply -f k8s/configmap.yaml

# Step 5.5: Create Persistent Volume Claims
echo ""
echo "Step 5.5: Creating Persistent Volume Claims..."
kubectl apply -f k8s/persistent-volumes.yaml

# Step 6: Deploy MongoDB
echo ""
echo "Step 6: Deploying MongoDB..."
kubectl apply -f k8s/mongodb-deployment.yaml

# Step 7: Deploy Redis
echo ""
echo "Step 7: Deploying Redis..."
kubectl apply -f k8s/redis-deployment.yaml

# Wait for databases to be ready
echo ""
echo "Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/mongodb -n inventory-prod
kubectl wait --for=condition=available --timeout=120s deployment/redis -n inventory-prod

# Step 8: Deploy Application
echo ""
echo "Step 8: Deploying Application..."
kubectl apply -f k8s/app-deployment.yaml

# Wait for app to be ready
echo ""
echo "Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/inventory-app -n inventory-prod

# Step 9: Get service information
echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "To access the application:"
echo "1. Run: minikube service inventory-service -n inventory-prod"
echo ""
echo "To check pod status:"
echo "kubectl get pods -n inventory-prod"
echo ""
echo "To view logs:"
echo "kubectl logs -f deployment/inventory-app -n inventory-prod"
echo ""
echo "To port-forward directly:"
echo "kubectl port-forward -n inventory-prod svc/inventory-service 3000:80"
echo "Then access: http://localhost:3000"
echo ""
