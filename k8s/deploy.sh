#!/bin/bash
# Kubernetes Deployment Script for Inventory Manager

set -e

echo "🚀 Deploying Inventory Manager to Kubernetes..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml

# Create secrets (IMPORTANT: Update secrets.yaml with actual values first!)
echo -e "${YELLOW}⚠️  WARNING: Make sure to update k8s/secrets.yaml with actual secrets!${NC}"
read -p "Have you updated secrets.yaml with production values? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Please update secrets.yaml before deployment${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating secrets...${NC}"
kubectl apply -f k8s/secrets.yaml

# Create ConfigMap
echo -e "${YELLOW}Creating ConfigMap...${NC}"
kubectl apply -f k8s/configmap.yaml

# Create Persistent Volumes
echo -e "${YELLOW}Creating Persistent Volume Claims...${NC}"
kubectl apply -f k8s/persistent-volumes.yaml

# Wait for PVCs to be bound
echo -e "${YELLOW}Waiting for PVCs to be ready...${NC}"
kubectl wait --for=condition=Bound pvc/mongodb-pvc -n inventory-manager --timeout=60s
kubectl wait --for=condition=Bound pvc/redis-pvc -n inventory-manager --timeout=60s

# Deploy MongoDB
echo -e "${YELLOW}Deploying MongoDB...${NC}"
kubectl apply -f k8s/mongodb-deployment.yaml

# Wait for MongoDB to be ready
echo -e "${YELLOW}Waiting for MongoDB to be ready...${NC}"
kubectl wait --for=condition=available deployment/mongodb -n inventory-manager --timeout=300s

# Deploy Redis
echo -e "${YELLOW}Deploying Redis...${NC}"
kubectl apply -f k8s/redis-deployment.yaml

# Wait for Redis to be ready
echo -e "${YELLOW}Waiting for Redis to be ready...${NC}"
kubectl wait --for=condition=available deployment/redis -n inventory-manager --timeout=120s

# Deploy Application
echo -e "${YELLOW}Deploying Inventory Manager Application...${NC}"
kubectl apply -f k8s/app-deployment.yaml

# Wait for Application to be ready
echo -e "${YELLOW}Waiting for Application to be ready...${NC}"
kubectl wait --for=condition=available deployment/inventory-app -n inventory-manager --timeout=300s

# Apply Network Policies
echo -e "${YELLOW}Applying Network Policies...${NC}"
kubectl apply -f k8s/network-policies.yaml

# Apply Ingress (optional)
if [ -f "k8s/ingress.yaml" ]; then
    echo -e "${YELLOW}Applying Ingress...${NC}"
    kubectl apply -f k8s/ingress.yaml
fi

# Display deployment status
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Deployment Status:"
kubectl get all -n inventory-manager
echo ""
echo "Service URLs:"
kubectl get svc -n inventory-manager

# Get the service URL
echo ""
echo -e "${GREEN}🎉 Inventory Manager deployed successfully!${NC}"
echo ""
echo "To access the application:"
echo "  kubectl port-forward svc/inventory-service 3000:80 -n inventory-manager"
echo "  Then visit: http://localhost:3000"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/inventory-app -n inventory-manager"
echo ""
echo "To scale the application:"
echo "  kubectl scale deployment/inventory-app --replicas=5 -n inventory-manager"
