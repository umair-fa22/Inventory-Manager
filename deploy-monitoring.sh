#!/bin/bash

# Monitoring Stack Deployment Script
# Deploys Prometheus and Grafana for Inventory Manager

set -e

echo "======================================"
echo "Monitoring Stack Deployment"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running in Kubernetes or Docker Compose
if command -v kubectl &> /dev/null; then
    DEPLOYMENT_TYPE="kubernetes"
    print_info "Kubernetes detected - will deploy to K8s"
elif command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
    DEPLOYMENT_TYPE="docker"
    print_info "Docker detected - will deploy with Docker Compose"
else
    print_error "Neither kubectl nor docker-compose found!"
    exit 1
fi

# Deploy based on environment
if [ "$DEPLOYMENT_TYPE" = "kubernetes" ]; then
    echo ""
    echo "Deploying to Kubernetes..."
    echo "----------------------------"
    
    # Create monitoring namespace
    print_info "Creating monitoring namespace..."
    kubectl apply -f k8s/prometheus-deployment.yaml
    
    # Deploy Grafana
    print_info "Deploying Grafana..."
    kubectl apply -f k8s/grafana-deployment.yaml
    
    # Wait for pods to be ready
    print_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=node-exporter -n monitoring --timeout=120s || true
    
    # Get service information
    echo ""
    print_success "Deployment complete!"
    echo ""
    echo "==================================="
    echo "Access Information"
    echo "==================================="
    
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    
    echo ""
    echo "Prometheus:"
    echo "  URL: http://$NODE_IP:30090"
    echo "  Port Forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
    echo ""
    echo "Grafana:"
    echo "  URL: http://$NODE_IP:30300"
    echo "  Port Forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    echo "Dashboard: Navigate to Dashboards → Inventory Manager Dashboard"
    echo ""
    
    # Show pod status
    echo "==================================="
    echo "Pod Status"
    echo "==================================="
    kubectl get pods -n monitoring
    
elif [ "$DEPLOYMENT_TYPE" = "docker" ]; then
    echo ""
    echo "Deploying with Docker Compose..."
    echo "--------------------------------"
    
    # Check if monitoring directory exists
    if [ ! -d "monitoring" ]; then
        print_error "monitoring/ directory not found!"
        exit 1
    fi
    
    # Start services
    print_info "Starting monitoring services..."
    docker-compose up -d prometheus grafana node-exporter
    
    # Wait for services to be healthy
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker ps | grep -q "inventory-prometheus"; then
        print_success "Prometheus is running"
    else
        print_error "Prometheus failed to start"
    fi
    
    if docker ps | grep -q "inventory-grafana"; then
        print_success "Grafana is running"
    else
        print_error "Grafana failed to start"
    fi
    
    if docker ps | grep -q "inventory-node-exporter"; then
        print_success "Node Exporter is running"
    else
        print_error "Node Exporter failed to start"
    fi
    
    echo ""
    print_success "Deployment complete!"
    echo ""
    echo "==================================="
    echo "Access Information"
    echo "==================================="
    echo ""
    echo "Prometheus:"
    echo "  URL: http://localhost:9090"
    echo "  Targets: http://localhost:9090/targets"
    echo ""
    echo "Grafana:"
    echo "  URL: http://localhost:3001"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    echo "Node Exporter:"
    echo "  Metrics: http://localhost:9100/metrics"
    echo ""
    echo "Application Metrics:"
    echo "  URL: http://localhost:3000/metrics"
    echo ""
    echo "Dashboard: Navigate to Dashboards → Inventory Manager Dashboard"
    echo ""
    echo "==================================="
    echo "Running Containers"
    echo "==================================="
    docker ps --filter "name=inventory-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

echo ""
print_info "For detailed setup instructions, see MONITORING.md"
echo ""
