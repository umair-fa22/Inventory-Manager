# Deployment Guide

This document provides comprehensive deployment instructions for the Inventory Manager application across different environments.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Local Development with Docker Compose](#local-development-with-docker-compose)
- [Production Deployment with Kubernetes](#production-deployment-with-kubernetes)
- [Security Best Practices](#security-best-practices)
- [Verification & Testing](#verification--testing)

## Architecture Overview

The Inventory Manager is built with a microservices-ready architecture:

```
┌─────────────────┐
│   Load Balancer │
│    / Ingress    │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  Flask   │ (3+ replicas, autoscaling)
    │   App    │
    └──┬────┬──┘
       │    │
   ┌───▼──┐ │
   │Redis │ │ (Cache + Message Queue)
   └──────┘ │
            │
        ┌───▼────┐
        │MongoDB │ (Database)
        └────────┘
```

### Components:
- **Flask Application**: REST API with caching and pub/sub support
- **MongoDB**: Primary database with persistent storage
- **Redis**: Caching layer and message queue for inter-service communication
- **All services**: Containerized with health checks and no hardcoded secrets

## Prerequisites

### For Docker Compose (Local Development):
- Docker Engine 20.10+
- Docker Compose v2.0+
- 4GB RAM available
- 10GB disk space

### For Kubernetes (Production):
- Kubernetes cluster 1.24+
- kubectl configured
- Container registry access
- Persistent volume provisioner
- Ingress controller (optional)

## Local Development with Docker Compose

### 1. Setup Environment

```bash
# Clone the repository
git clone <repository-url>
cd Inventory-Manager

# Create .env file from example
cp .env.example .env

# Edit .env and set secure passwords
nano .env
```

Update the following in `.env`:
```bash
MONGO_USERNAME=admin
MONGO_PASSWORD=<generate-secure-password>
REDIS_PASSWORD=<generate-secure-password>
DATABASE=inventory_db
COLLECTION=items
```

Generate secure passwords:
```bash
# For MongoDB password
openssl rand -base64 32

# For Redis password
openssl rand -base64 32
```

### 2. Build and Start Services

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 3. Verify Deployment

```bash
# Check MongoDB is running
docker-compose exec mongo mongosh --eval "db.adminCommand('ping')"

# Check Redis is running
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} ping

# Test application
curl http://localhost:3000/api/items
```

### 4. Access Application

Open your browser and navigate to:
- Application: http://localhost:3000
- API Endpoint: http://localhost:3000/api/items

### 5. Network Verification

```bash
# Verify container networking
docker network inspect inventory-network

# Check containers can communicate
docker-compose exec inventory-manager ping mongo
docker-compose exec inventory-manager ping redis
```

### 6. Persistent Storage Verification

```bash
# List volumes
docker volume ls | grep inventory

# Inspect MongoDB volume
docker volume inspect inventory-mongodb-data

# Inspect Redis volume
docker volume inspect inventory-redis-data
```

### 7. Stop and Cleanup

```bash
# Stop services (keep data)
docker-compose down

# Stop and remove volumes (delete data)
docker-compose down -v

# Stop and remove images
docker-compose down --rmi all
```

## Production Deployment with Kubernetes

See [k8s/README.md](k8s/README.md) for detailed Kubernetes deployment instructions.

### Quick Start

```bash
# 1. Build and push image
docker build -t your-registry.com/inventory-manager:latest .
docker push your-registry.com/inventory-manager:latest

# 2. Update image reference in k8s/app-deployment.yaml

# 3. Create secrets
kubectl create secret generic inventory-secrets \
  --namespace=inventory-manager \
  --from-literal=mongo-username=admin \
  --from-literal=mongo-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32)

# 4. Deploy
cd k8s
./deploy.sh
```

## Security Best Practices

### ✅ Implemented Security Features:

1. **No Hardcoded Secrets**
   - All credentials via environment variables
   - `.env` file excluded from Git
   - Kubernetes Secrets for production

2. **Container Security**
   - Multi-stage builds (reduced attack surface)
   - Non-root user (UID 1000)
   - Read-only root filesystem where possible
   - No new privileges
   - Dropped capabilities

3. **Network Security**
   - Isolated bridge network
   - Network policies in Kubernetes
   - Service-to-service communication only
   - No external database access (ClusterIP)

4. **Resource Limits**
   - CPU and memory limits set
   - Prevents resource exhaustion
   - Autoscaling configured

5. **Health Checks**
   - Liveness probes (restart unhealthy)
   - Readiness probes (remove from load balancer)
   - Startup probes for slow-starting apps

### 🔒 Additional Production Recommendations:

1. **Secrets Management**
   ```bash
   # Use external secrets operator
   kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
   
   # Or sealed secrets
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
   ```

2. **TLS/HTTPS**
   ```bash
   # Install cert-manager
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   
   # Update ingress.yaml with TLS config
   ```

3. **Database Backups**
   ```bash
   # MongoDB backup
   kubectl exec -it deployment/mongodb -n inventory-manager -- \
     mongodump --out /tmp/backup
   
   # Schedule with CronJob
   ```

4. **Monitoring**
   ```bash
   # Prometheus + Grafana
   helm install prometheus prometheus-community/kube-prometheus-stack
   ```

5. **Image Scanning**
   ```bash
   # Scan for vulnerabilities
   docker scan inventory-manager:latest
   
   # Or use Trivy
   trivy image inventory-manager:latest
   ```

## Verification & Testing

### Container Networking Test

```bash
# Docker Compose
docker-compose exec inventory-manager sh -c "
  echo 'Testing MongoDB connection...' && \
  nc -zv mongo 27017 && \
  echo 'Testing Redis connection...' && \
  nc -zv redis 6379
"

# Kubernetes
kubectl run -it --rm debug --image=busybox --restart=Never -n inventory-manager -- sh
# Inside pod:
# nslookup mongodb-service
# nslookup redis-service
```

### Persistent Storage Test

```bash
# Docker Compose
# 1. Add test data
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","unitPrice":10,"quantity":5}'

# 2. Restart services
docker-compose restart

# 3. Verify data persists
curl http://localhost:3000/api/items

# Kubernetes
# Similar process using kubectl port-forward
```

### Cache Test (Redis)

```bash
# First request (cache miss)
time curl http://localhost:3000/api/items

# Second request (cache hit - should be faster)
time curl http://localhost:3000/api/items

# Verify Redis has data
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} KEYS '*'
```

### Security Test

```bash
# Verify no secrets in image
docker history inventory-manager:latest | grep -i password

# Verify non-root user
docker-compose exec inventory-manager whoami
# Should output: appuser

# Verify dropped capabilities (Kubernetes)
kubectl exec deployment/inventory-app -n inventory-manager -- sh -c "cat /proc/1/status | grep Cap"
```

### Load Test

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://localhost:3000/api/items

# Test with POST requests
ab -n 100 -c 5 -p data.json -T "application/json" http://localhost:3000/api/items
```

### Health Check Test

```bash
# Docker Compose
docker-compose ps
# All services should show "healthy"

# Kubernetes
kubectl get pods -n inventory-manager
# All pods should show "Ready"

# Check specific pod health
kubectl describe pod <pod-name> -n inventory-manager | grep -A 5 Liveness
```

## Troubleshooting

### Issue: Services can't communicate

```bash
# Check network exists
docker network ls | grep inventory

# Check containers are on same network
docker inspect inventory-app | grep NetworkMode
docker inspect inventory-mongodb | grep NetworkMode

# Test connectivity
docker-compose exec inventory-manager nc -zv mongo 27017
```

### Issue: Data not persisting

```bash
# Verify volumes exist
docker volume ls | grep inventory

# Check volume mounts
docker inspect inventory-mongodb | grep -A 10 Mounts

# Verify write permissions
docker-compose exec mongo ls -la /data/db
```

### Issue: Secrets not loading

```bash
# Verify .env file exists
ls -la .env

# Check environment variables in container
docker-compose exec inventory-manager env | grep MONGO

# Kubernetes: Check secret
kubectl get secret inventory-secrets -n inventory-manager -o yaml
```

### Issue: Out of memory

```bash
# Check resource usage
docker stats

# Kubernetes: Check pod resources
kubectl top pods -n inventory-manager

# Increase memory limits in docker-compose.yml or k8s manifests
```

## Scaling

### Docker Compose

```bash
# Scale application instances
docker-compose up -d --scale inventory-manager=3

# Note: Need to remove port mapping conflicts
```

### Kubernetes

```bash
# Manual scaling
kubectl scale deployment/inventory-app --replicas=5 -n inventory-manager

# Autoscaling is already configured via HPA
kubectl get hpa -n inventory-manager
```

## Backup & Recovery

### MongoDB Backup

```bash
# Docker Compose
docker-compose exec mongo mongodump --out /tmp/backup --db inventory_db

# Copy backup out
docker cp inventory-mongodb:/tmp/backup ./mongodb-backup

# Restore
docker-compose exec mongo mongorestore /tmp/backup
```

### Redis Backup

```bash
# Redis automatically saves to disk (AOF enabled)
# To trigger manual save:
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} BGSAVE
```

## Support

For issues or questions:
- Check logs: `docker-compose logs -f` or `kubectl logs -f deployment/inventory-app -n inventory-manager`
- Review [k8s/README.md](k8s/README.md) for Kubernetes-specific issues
- See main [README.md](README.md) for application documentation
