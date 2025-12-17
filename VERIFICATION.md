# Infrastructure Verification Checklist

This document provides a comprehensive checklist to verify all infrastructure requirements are met.

## ✅ Requirements Verification

### 1. Database ✓
- [x] MongoDB integrated with persistent storage
- [x] Connection via environment variables (no hardcoded credentials)
- [x] Health checks configured
- [x] Data persistence across container restarts verified
- [x] Indexed collections for performance

**Verification Commands:**
```bash
# Docker Compose
docker-compose exec mongo mongosh --eval "db.adminCommand('ping')"
docker volume inspect inventory-mongodb-data

# Kubernetes
kubectl exec -it deployment/mongodb -n inventory-manager -- mongosh --eval "db.adminCommand('ping')"
kubectl get pvc mongodb-pvc -n inventory-manager
```

### 2. Cache/Message Queue ✓
- [x] Redis integrated for caching
- [x] Redis pub/sub for message queue functionality
- [x] Automatic cache invalidation on data changes
- [x] TTL configuration for cache entries (5 minutes default)
- [x] Persistent AOF storage for Redis
- [x] Health checks configured

**Verification Commands:**
```bash
# Docker Compose
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} ping
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} KEYS '*'

# Kubernetes
kubectl exec -it deployment/redis -n inventory-manager -- redis-cli -a <password> ping
```

**Cache Test:**
```bash
# First request (cache miss)
time curl http://localhost:3000/api/items

# Second request (cache hit - faster)
time curl http://localhost:3000/api/items
```

### 3. Dockerfile (Optimized, Multi-stage) ✓
- [x] Multi-stage build (builder + runtime)
- [x] Minimal base image (python:3.13-slim)
- [x] Non-root user (appuser, UID 1000)
- [x] No secrets in image layers
- [x] Optimized layer caching
- [x] Production WSGI server (Gunicorn)
- [x] Health check defined
- [x] Security hardening applied

**Verification Commands:**
```bash
# Check image size
docker images inventory-manager

# Verify no secrets in history
docker history inventory-manager:latest | grep -i password

# Verify user
docker-compose exec inventory-manager whoami
# Should output: appuser

# Check security
docker inspect inventory-manager | jq '.[0].Config.User'
```

### 4. Docker Compose (Local Testing) ✓
- [x] All services defined (app, MongoDB, Redis)
- [x] Environment variables from .env file
- [x] Service dependencies with health checks
- [x] Resource limits configured
- [x] Restart policies set
- [x] Security options (no-new-privileges)
- [x] Isolated network with defined subnet

**Verification Commands:**
```bash
# Check all services running
docker-compose ps

# Verify all services healthy
docker-compose ps | grep -c "healthy"

# View resource limits
docker stats --no-stream
```

### 5. Container Networking ✓
- [x] Custom bridge network created
- [x] Network isolation verified
- [x] Service-to-service communication via DNS
- [x] Subnet defined (172.20.0.0/16)
- [x] Network policies in Kubernetes

**Verification Commands:**
```bash
# Docker Compose
# Check network exists
docker network ls | grep inventory-network

# Inspect network
docker network inspect inventory-network

# Test connectivity from app to services
docker-compose exec inventory-manager sh -c "nc -zv mongo 27017 && nc -zv redis 6379"

# Kubernetes
kubectl get networkpolicy -n inventory-manager
kubectl describe networkpolicy mongodb-network-policy -n inventory-manager
```

**Network Test Script:**
```bash
# Run from project root
./scripts/test-networking.sh
```

### 6. Persistent Storage ✓
- [x] MongoDB data volume configured
- [x] MongoDB config volume configured
- [x] Redis AOF volume configured
- [x] Named volumes for easy management
- [x] Data survives container restarts
- [x] PersistentVolumeClaims in Kubernetes

**Verification Commands:**
```bash
# Docker Compose
# List volumes
docker volume ls | grep inventory

# Inspect MongoDB volume
docker volume inspect inventory-mongodb-data

# Test persistence
# 1. Add data
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","unitPrice":10,"quantity":5}'

# 2. Restart containers
docker-compose restart

# 3. Verify data persists
curl http://localhost:3000/api/items

# Kubernetes
kubectl get pvc -n inventory-manager
kubectl describe pvc mongodb-pvc -n inventory-manager
```

### 7. No Hardcoded Secrets ✓
- [x] .env.example template provided
- [x] .env in .gitignore
- [x] All secrets via environment variables
- [x] Kubernetes Secrets manifest
- [x] Docker secrets not in image
- [x] Instructions for secure secret generation

**Verification Commands:**
```bash
# Check .env not in Git
git status | grep .env
# Should show nothing or .env.example only

# Verify secrets not in Dockerfile
grep -i password Dockerfile
# Should show nothing

# Verify secrets not in docker-compose
grep -E "password|secret" docker-compose.yml | grep -v '\${'
# Should show only variable references, no values

# Check image history
docker history inventory-manager:latest --no-trunc | grep -i "password\|secret"
# Should show nothing

# Kubernetes
kubectl get secret inventory-secrets -n inventory-manager
kubectl describe secret inventory-secrets -n inventory-manager
# Should show keys but not values
```

### 8. Microservices/Kubernetes Extensibility ✓
- [x] Kubernetes manifests in k8s/ directory
- [x] Namespace isolation
- [x] ConfigMaps for configuration
- [x] Secrets for sensitive data
- [x] Service discovery
- [x] Horizontal Pod Autoscaler
- [x] Rolling updates configured
- [x] Network policies for security
- [x] Ingress for external access
- [x] Resource requests and limits

**Kubernetes Files:**
```
k8s/
├── namespace.yaml              # Namespace isolation
├── secrets.yaml                # Secret management
├── configmap.yaml              # Configuration
├── persistent-volumes.yaml     # PVC definitions
├── mongodb-deployment.yaml     # MongoDB StatefulSet
├── redis-deployment.yaml       # Redis deployment
├── app-deployment.yaml         # App + HPA
├── network-policies.yaml       # Network security
├── ingress.yaml                # External access
├── deploy.sh                   # Deployment script
└── README.md                   # K8s documentation
```

**Verification Commands:**
```bash
# Deploy to Kubernetes
cd k8s && ./deploy.sh

# Verify all resources
kubectl get all -n inventory-manager

# Check services
kubectl get svc -n inventory-manager

# Verify PVCs bound
kubectl get pvc -n inventory-manager

# Check network policies
kubectl get networkpolicy -n inventory-manager

# Test autoscaling
kubectl get hpa -n inventory-manager
```

## 🔒 Security Verification

### Container Security
```bash
# Verify non-root user
docker-compose exec inventory-manager id
# uid=1000(appuser) gid=1000(appuser)

# Check no-new-privileges
docker inspect inventory-app | jq '.[0].HostConfig.SecurityOpt'
# Should include "no-new-privileges:true"

# Kubernetes security context
kubectl get pod -n inventory-manager -o jsonpath='{.items[0].spec.containers[0].securityContext}'
```

### Network Security
```bash
# Docker: Verify isolated network
docker network inspect inventory-network | jq '.[0].Containers'

# Kubernetes: Test network policies
kubectl run test-pod --rm -it --image=busybox -n default -- nc -zv mongodb-service.inventory-manager.svc.cluster.local 27017
# Should fail (blocked by network policy)
```

### Secrets Security
```bash
# Verify .env not tracked
git ls-files | grep ".env$"
# Should return nothing

# Check environment in running container
docker-compose exec inventory-manager env | grep -E "PASSWORD|SECRET"
# Should show variable names but not expose secrets in logs
```

## 📊 Performance Verification

### Cache Performance
```bash
# Measure cache hit improvement
echo "First request (cache miss):"
time curl -s http://localhost:3000/api/items > /dev/null

echo "Second request (cache hit):"
time curl -s http://localhost:3000/api/items > /dev/null
# Second request should be significantly faster
```

### Load Testing
```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Run load test
ab -n 1000 -c 10 http://localhost:3000/api/items

# Check autoscaling (Kubernetes)
kubectl get hpa -w -n inventory-manager
# Watch HPA scale pods under load
```

### Resource Usage
```bash
# Docker Compose
docker stats --no-stream

# Kubernetes
kubectl top pods -n inventory-manager
kubectl top nodes
```

## 🧪 Integration Testing

### Complete Workflow Test
```bash
# 1. Start services
docker-compose up -d

# 2. Wait for healthy
sleep 30
docker-compose ps

# 3. Test API
# Create item
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Widget","unitPrice":99.99,"quantity":10}'

# Get all items (cached)
curl http://localhost:3000/api/items

# Update item (invalidates cache)
ITEM_ID=$(curl -s http://localhost:3000/api/items | jq -r '.[0].id')
curl -X PUT http://localhost:3000/api/items/$ITEM_ID \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Widget","unitPrice":89.99,"quantity":15}'

# Verify cache invalidation
curl http://localhost:3000/api/items

# Delete item
curl -X DELETE http://localhost:3000/api/items/$ITEM_ID

# 4. Verify persistence
docker-compose restart
sleep 20
curl http://localhost:3000/api/items
```

## 📋 Deployment Checklist

### Before Deployment
- [ ] `.env` file created with secure passwords
- [ ] No secrets in Git repository
- [ ] Docker and Docker Compose installed
- [ ] Ports 3000, 6379, 27017 available

### Docker Compose Deployment
- [ ] `docker-compose up -d` succeeds
- [ ] All services show "healthy"
- [ ] Application accessible at http://localhost:3000
- [ ] API responds at http://localhost:3000/api/items
- [ ] Data persists after restart

### Kubernetes Deployment
- [ ] Cluster accessible via kubectl
- [ ] Image pushed to container registry
- [ ] Secrets created securely
- [ ] Storage class available
- [ ] `./k8s/deploy.sh` succeeds
- [ ] All pods running and ready
- [ ] Services expose correct ports
- [ ] PVCs bound to PVs
- [ ] Network policies applied
- [ ] Application accessible via ingress/port-forward

## 📝 Summary

All requirements met:

1. ✅ **Database**: MongoDB with persistent storage
2. ✅ **Cache/Message Queue**: Redis with AOF persistence
3. ✅ **Dockerfile**: Optimized multi-stage with security hardening
4. ✅ **Docker Compose**: Complete local testing environment
5. ✅ **Container Networking**: Verified bridge network with DNS
6. ✅ **Persistent Storage**: All data services have persistent volumes
7. ✅ **No Hardcoded Secrets**: All secrets via environment variables
8. ✅ **Kubernetes Ready**: Complete k8s manifests for production

## 🚀 Quick Verification Script

Run this script to verify all requirements:

```bash
#!/bin/bash
echo "=== Inventory Manager Infrastructure Verification ==="

echo "1. Checking Docker Compose services..."
docker-compose ps

echo "2. Testing MongoDB connection..."
docker-compose exec -T mongo mongosh --quiet --eval "db.adminCommand('ping')"

echo "3. Testing Redis connection..."
docker-compose exec -T redis redis-cli -a ${REDIS_PASSWORD} ping

echo "4. Testing application endpoint..."
curl -f http://localhost:3000/api/items

echo "5. Verifying persistent volumes..."
docker volume ls | grep inventory

echo "6. Checking network..."
docker network inspect inventory-network > /dev/null && echo "Network OK"

echo "7. Verifying no secrets in Git..."
git status | grep -q ".env" && echo "WARNING: .env in Git!" || echo "Secrets OK"

echo "=== Verification Complete ==="
```

Save as `verify-infrastructure.sh` and run with `bash verify-infrastructure.sh`
