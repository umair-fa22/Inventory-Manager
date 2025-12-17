# Quick Reference Card

## 🚀 Essential Commands

### Local Development (Docker Compose)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Clean everything (including data)
docker-compose down -v
```

### Kubernetes Deployment

```bash
# Deploy everything
cd k8s && ./deploy.sh

# Get all resources
kubectl get all -n inventory-manager

# View logs
kubectl logs -f deployment/inventory-app -n inventory-manager

# Port forward to access
kubectl port-forward svc/inventory-service 3000:80 -n inventory-manager

# Scale application
kubectl scale deployment/inventory-app --replicas=5 -n inventory-manager

# Delete everything
kubectl delete namespace inventory-manager
```

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `.env` | Local secrets (never commit!) |
| `.env.example` | Template for .env file |
| `docker-compose.yml` | Local development stack |
| `Dockerfile` | Application container image |
| `k8s/*.yaml` | Kubernetes manifests |

## 🔑 Environment Variables

### Required Variables
```bash
MONGO_USERNAME=admin
MONGO_PASSWORD=<secure-password>
REDIS_PASSWORD=<secure-password>
DATABASE=inventory_db
COLLECTION=items
```

### Optional Variables
```bash
PORT=3000
APP_PORT=3000
REDIS_HOST=redis
REDIS_PORT=6379
CACHE_TTL=300
```

## 🌐 Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web UI |
| `/api/items` | GET | List all items (cached) |
| `/api/items` | POST | Create new item |
| `/api/items/<id>` | GET | Get item by ID (cached) |
| `/api/items/<id>` | PUT | Update item |
| `/api/items/<id>` | DELETE | Delete item |

## 🔍 Verification Commands

```bash
# Run automated verification
./verify-infrastructure.sh

# Test MongoDB
docker-compose exec mongo mongosh --eval "db.adminCommand('ping')"

# Test Redis
docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} ping

# Test API
curl http://localhost:3000/api/items

# Test cache performance
time curl http://localhost:3000/api/items  # First (miss)
time curl http://localhost:3000/api/items  # Second (hit)
```

## 🐳 Docker Commands

```bash
# Build image
docker build -t inventory-manager:latest .

# Run standalone container
docker run -d -p 3000:3000 \
  -e MONGODB_URI=... \
  -e REDIS_HOST=... \
  inventory-manager:latest

# View container logs
docker logs -f inventory-app

# Execute command in container
docker exec -it inventory-app sh

# View volumes
docker volume ls | grep inventory

# Inspect network
docker network inspect inventory-network
```

## 📊 Monitoring

```bash
# Resource usage
docker stats

# Kubernetes resource usage
kubectl top pods -n inventory-manager
kubectl top nodes

# View HPA status
kubectl get hpa -n inventory-manager -w
```

## 🔒 Security Commands

```bash
# Generate secure password
openssl rand -base64 32

# Create Kubernetes secret
kubectl create secret generic inventory-secrets \
  --namespace=inventory-manager \
  --from-literal=mongo-username=admin \
  --from-literal=mongo-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32)

# Verify no secrets in Git
git status | grep .env

# Check container user
docker-compose exec inventory-manager whoami
```

## 🧪 Testing

```bash
# Create test item
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","unitPrice":10.99,"quantity":5}'

# Get all items
curl http://localhost:3000/api/items

# Update item
curl -X PUT http://localhost:3000/api/items/<id> \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated","unitPrice":15.99,"quantity":10}'

# Delete item
curl -X DELETE http://localhost:3000/api/items/<id>
```

## 🛠️ Troubleshooting

```bash
# Check service dependencies
docker-compose exec inventory-manager nc -zv mongo 27017
docker-compose exec inventory-manager nc -zv redis 6379

# View detailed logs
docker-compose logs --tail=100 inventory-manager

# Restart specific service
docker-compose restart inventory-manager

# Rebuild image
docker-compose up -d --build

# Kubernetes pod issues
kubectl describe pod <pod-name> -n inventory-manager
kubectl logs <pod-name> -n inventory-manager --previous
```

## 📚 Documentation

- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Complete implementation summary
- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide
- [VERIFICATION.md](VERIFICATION.md) - Verification checklist
- [k8s/README.md](k8s/README.md) - Kubernetes guide
- [DOCKER.md](DOCKER.md) - Docker setup guide

## 🏗️ Architecture

```
Internet → Ingress → Service → Pods (3-10 replicas)
                                  ↓
                           ┌──────┴──────┐
                           ↓             ↓
                        MongoDB       Redis
                        (10Gi PV)    (1Gi PV)
```

## ⚡ Performance Tips

1. **Cache warming**: Pre-populate Redis on startup
2. **Database indexes**: Add indexes for frequently queried fields
3. **Connection pooling**: Already configured in MongoDB client
4. **Resource limits**: Adjust based on load testing
5. **HPA tuning**: Adjust CPU/memory thresholds

## 🎯 Production Checklist

- [ ] Change default passwords in `.env`
- [ ] Create Kubernetes secrets securely
- [ ] Configure ingress with your domain
- [ ] Set up TLS certificates (cert-manager)
- [ ] Configure backups for databases
- [ ] Set up monitoring (Prometheus)
- [ ] Configure log aggregation
- [ ] Review resource limits
- [ ] Test disaster recovery
- [ ] Document runbooks

## 💡 Quick Tips

- Use `docker-compose up -d` for background mode
- Use `kubectl get events -n inventory-manager` to debug K8s issues
- Redis cache has 5-minute TTL by default (configurable)
- All data persists across restarts in volumes
- Network policies restrict access between services
- HPA automatically scales based on load
- Health checks ensure zero-downtime deployments

---

**Need Help?** Check the comprehensive guides in the documentation files!
