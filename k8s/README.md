# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the Inventory Manager application in a production-ready, microservices-oriented architecture.

## Architecture

The deployment consists of three main components:

1. **MongoDB** - Database with persistent storage
2. **Redis** - Cache and message queue with persistent storage
3. **Inventory App** - Flask application (3+ replicas with autoscaling)

All components use:
- Secrets management (no hardcoded credentials)
- Network policies for security
- Resource limits and requests
- Health checks (liveness and readiness probes)
- Persistent storage for data durability

## Prerequisites

- Kubernetes cluster (v1.24+)
- `kubectl` configured to access your cluster
- Container registry access (for pushing app image)
- Ingress controller (optional, for external access)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t your-registry.com/inventory-manager:latest .

# Push to registry
docker push your-registry.com/inventory-manager:latest
```

### 2. Update Configuration

Edit `k8s/app-deployment.yaml` and update the image reference:
```yaml
image: your-registry.com/inventory-manager:latest
```

### 3. Create Secrets

**IMPORTANT**: Never commit actual secrets to Git!

Option A - Using kubectl:
```bash
kubectl create secret generic inventory-secrets \
  --namespace=inventory-manager \
  --from-literal=mongo-username=admin \
  --from-literal=mongo-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml > k8s/secrets-generated.yaml

kubectl apply -f k8s/secrets-generated.yaml
```

Option B - Update secrets.yaml manually (not recommended for production):
```bash
# Edit k8s/secrets.yaml and replace placeholders
kubectl apply -f k8s/secrets.yaml
```

### 4. Deploy All Components

```bash
# Make deploy script executable
chmod +x k8s/deploy.sh

# Run deployment
./k8s/deploy.sh
```

Or deploy manually:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/persistent-volumes.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/network-policies.yaml
kubectl apply -f k8s/ingress.yaml  # Optional
```

## Files Description

- **namespace.yaml** - Creates dedicated namespace for isolation
- **secrets.yaml** - Stores sensitive credentials (MongoDB, Redis passwords)
- **configmap.yaml** - Non-sensitive configuration values
- **persistent-volumes.yaml** - PVC definitions for MongoDB and Redis
- **mongodb-deployment.yaml** - MongoDB StatefulSet/Deployment with service
- **redis-deployment.yaml** - Redis Deployment with service
- **app-deployment.yaml** - Application Deployment, Service, and HPA
- **network-policies.yaml** - Network security policies
- **ingress.yaml** - Ingress for external access (optional)

## Accessing the Application

### Port Forward (Development/Testing)
```bash
kubectl port-forward svc/inventory-service 3000:80 -n inventory-manager
# Access: http://localhost:3000
```

### LoadBalancer (Cloud Provider)
```bash
kubectl get svc inventory-service -n inventory-manager
# Use EXTERNAL-IP shown
```

### Ingress (Production)
Update `k8s/ingress.yaml` with your domain and apply.

## Management Commands

### View Resources
```bash
# All resources
kubectl get all -n inventory-manager

# Pods with details
kubectl get pods -n inventory-manager -o wide

# Services
kubectl get svc -n inventory-manager

# Persistent volumes
kubectl get pvc -n inventory-manager
```

### View Logs
```bash
# Application logs
kubectl logs -f deployment/inventory-app -n inventory-manager

# MongoDB logs
kubectl logs -f deployment/mongodb -n inventory-manager

# Redis logs
kubectl logs -f deployment/redis -n inventory-manager

# Logs from specific pod
kubectl logs -f <pod-name> -n inventory-manager
```

### Scaling
```bash
# Manual scaling
kubectl scale deployment/inventory-app --replicas=5 -n inventory-manager

# View HPA status
kubectl get hpa -n inventory-manager
```

### Execute Commands in Pods
```bash
# MongoDB shell
kubectl exec -it deployment/mongodb -n inventory-manager -- mongosh

# Redis CLI
kubectl exec -it deployment/redis -n inventory-manager -- redis-cli -a <password>

# Application shell
kubectl exec -it deployment/inventory-app -n inventory-manager -- /bin/sh
```

### Update Application
```bash
# Update image
kubectl set image deployment/inventory-app \
  inventory-app=your-registry.com/inventory-manager:v2.0 \
  -n inventory-manager

# Rollout status
kubectl rollout status deployment/inventory-app -n inventory-manager

# Rollback if needed
kubectl rollout undo deployment/inventory-app -n inventory-manager
```

## Network Policies

Network policies are applied to:
- Allow only app pods to access MongoDB
- Allow only app pods to access Redis
- Restrict external access to app pods only

To test network policies:
```bash
kubectl get networkpolicy -n inventory-manager
```

## Monitoring & Health Checks

All pods have:
- **Liveness probes** - Restart unhealthy containers
- **Readiness probes** - Remove unhealthy pods from service

Check health:
```bash
kubectl describe pod <pod-name> -n inventory-manager
```

## Resource Management

Resource requests and limits are configured for:
- CPU and memory allocation
- Horizontal Pod Autoscaling (HPA) based on CPU/memory usage

Current limits:
- **App**: 256Mi-512Mi memory, 250m-500m CPU
- **MongoDB**: 256Mi-512Mi memory, 250m-500m CPU
- **Redis**: 128Mi-256Mi memory, 100m-200m CPU

## Cleanup

To remove all resources:
```bash
kubectl delete namespace inventory-manager
```

Or individual components:
```bash
kubectl delete -f k8s/app-deployment.yaml
kubectl delete -f k8s/redis-deployment.yaml
kubectl delete -f k8s/mongodb-deployment.yaml
kubectl delete -f k8s/persistent-volumes.yaml
```

## Production Considerations

1. **Secrets Management**: Use tools like:
   - Sealed Secrets
   - External Secrets Operator
   - HashiCorp Vault
   - Cloud provider secrets managers (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

2. **Persistent Storage**: 
   - Use StorageClass with your cloud provider
   - Configure backups for PVs
   - Consider StatefulSets for databases

3. **Ingress & TLS**:
   - Use cert-manager for automatic TLS certificates
   - Configure proper DNS
   - Enable HTTPS redirect

4. **Monitoring**:
   - Deploy Prometheus & Grafana
   - Set up alerts
   - Use logging aggregation (ELK, Loki)

5. **High Availability**:
   - MongoDB replica sets
   - Redis Sentinel or Cluster mode
   - Multi-zone deployment

6. **CI/CD**:
   - Automate deployments with GitOps (ArgoCD, Flux)
   - Implement blue-green or canary deployments
   - Use Helm charts for templating

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n inventory-manager
kubectl logs <pod-name> -n inventory-manager
```

### Connection issues
```bash
# Test MongoDB connectivity
kubectl run -it --rm debug --image=mongo:7.0 --restart=Never -n inventory-manager -- \
  mongosh mongodb://mongodb-service:27017

# Test Redis connectivity
kubectl run -it --rm debug --image=redis:7-alpine --restart=Never -n inventory-manager -- \
  redis-cli -h redis-service -p 6379
```

### Check network policies
```bash
kubectl get networkpolicy -n inventory-manager
kubectl describe networkpolicy <policy-name> -n inventory-manager
```

## Support & Documentation

For more information:
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- Project README: `../README.md`
