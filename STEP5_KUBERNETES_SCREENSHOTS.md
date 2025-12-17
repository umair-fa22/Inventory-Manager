# Step 5 - Kubernetes Deployment - Quick Reference

## Deployment Summary

### ✅ All Requirements Met

**Kubernetes Cluster**: Minikube  
**Environment**: Production (inventory-prod namespace)  
**Components Deployed**: Application (3 replicas), MongoDB, Redis

---

## Required Screenshots/Outputs

### 1. kubectl get pods -n inventory-prod

```
NAME                            READY   STATUS    RESTARTS   AGE     IP            NODE
inventory-app-cdd9996cb-dswt5   1/1     Running   0          51s     10.244.0.18   minikube
inventory-app-cdd9996cb-f6sbc   1/1     Running   0          65s     10.244.0.17   minikube
inventory-app-cdd9996cb-k6mtz   1/1     Running   0          39s     10.244.0.19   minikube
mongodb-cbf68b56d-kfcws         1/1     Running   0          73s     10.244.0.16   minikube
redis-65c887dc8d-r92x7          1/1     Running   0          4m53s   10.244.0.15   minikube
```

**Status**: All 5 pods running successfully ✓

---

### 2. kubectl get svc -n inventory-prod

```
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
inventory-service   LoadBalancer   10.104.5.147     <pending>     80:31825/TCP   7m24s
mongodb-service     ClusterIP      10.109.89.145    <none>        27017/TCP      7m35s
redis-service       ClusterIP      10.108.208.170   <none>        6379/TCP       7m35s
```

**Status**: All services created and accessible ✓

---

### 3. kubectl describe pod inventory-app-cdd9996cb-dswt5 -n inventory-prod

```
Name:             inventory-app-cdd9996cb-dswt5
Namespace:        inventory-prod
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Wed, 17 Dec 2025 22:16:26 +0500
Labels:           app=inventory-app
                  pod-template-hash=cdd9996cb
                  tier=backend
Status:           Running
IP:               10.244.0.18
Controlled By:    ReplicaSet/inventory-app-cdd9996cb

Containers:
  inventory-app:
    Container ID:   docker://490363ae67e8282dbb7c562400c222a8634ea89832c0c38ff700371dab95f72b
    Image:          inventory-manager:latest
    Image ID:       docker://sha256:c0190826e005cf094c4a8fcdc5266eb662fb64c565dd70603cb06b49a9365f1d
    Port:           3000/TCP (http)
    State:          Running
    Ready:          True
    Restart Count:  0
    
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      250m
      memory:   256Mi
    
    Liveness:   http-get http://:3000/api/items delay=40s timeout=10s period=30s
    Readiness:  http-get http://:3000/api/items delay=10s timeout=5s period=10s
    
    Environment:
      PORT:            <set to the key 'PORT' of config map 'inventory-config'>
      DATABASE:        <set to the key 'DATABASE' of config map 'inventory-config'>
      COLLECTION:      <set to the key 'COLLECTION' of config map 'inventory-config'>
      CACHE_TTL:       <set to the key 'CACHE_TTL' of config map 'inventory-config'>
      REDIS_HOST:      <set to the key 'REDIS_HOST' of config map 'inventory-config'>
      REDIS_PORT:      <set to the key 'REDIS_PORT' of config map 'inventory-config'>
      MONGO_USERNAME:  <set to the key 'mongo-username' in secret 'inventory-secrets'>
      MONGO_PASSWORD:  <set to the key 'mongo-password' in secret 'inventory-secrets'>
      REDIS_PASSWORD:  <set to the key 'redis-password' in secret 'inventory-secrets'>
      MONGODB_URI:     mongodb://$(MONGO_USERNAME):$(MONGO_PASSWORD)@mongodb-service:27017/

Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  70s   default-scheduler  Successfully assigned inventory-prod/inventory-app-cdd9996cb-dswt5 to minikube
  Normal  Pulled     69s   kubelet            Container image "inventory-manager:latest" already present on machine
  Normal  Created    69s   kubelet            Created container: inventory-app
  Normal  Started    69s   kubelet            Started container inventory-app
```

**Status**: Pod healthy with proper configuration from ConfigMaps and Secrets ✓

---

## Additional Verification

### Namespaces

```bash
kubectl get namespaces
```

```
NAME                   STATUS   AGE
inventory-dev          Active   9m19s
inventory-prod         Active   9m19s
```

**Status**: Dev and Prod namespaces created ✓

---

### ConfigMaps and Secrets

```bash
kubectl get configmap,secret -n inventory-prod
```

```
NAME                         DATA   AGE
configmap/inventory-config   7      9m48s

NAME                        TYPE     DATA   AGE
secret/inventory-secrets    Opaque   3      7m2s
```

**Status**: Configuration and secrets properly deployed ✓

---

### Persistent Volumes

```bash
kubectl get pvc -n inventory-prod
```

```
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   AGE
mongodb-pvc   Bound    pvc-00501e30-330a-492f-9e88-99c0dd7c67dd   10Gi       RWO            3m24s
redis-pvc     Bound    pvc-011bc689-df40-48cb-b0c0-fe66d0bec37f   1Gi        RWO            9m45s
```

**Status**: Persistent storage configured for data persistence ✓

---

### Application Test

```bash
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -n inventory-prod -- curl -s http://inventory-service/api/items
```

```json
[{"id":"6942e5feee7082c7231bc238","name":"Eggs","quantity":24,"unitPrice":23}]
```

**Status**: API endpoint responding with data from MongoDB ✓

---

## Architecture Highlights

### 🔧 Application Communication

1. **App → MongoDB**: 
   - Via `mongodb-service:27017`
   - Authenticated with credentials from secrets
   - Database: `inventory_db`, Collection: `items`

2. **App → Redis**: 
   - Via `redis-service:6379`
   - Password-authenticated
   - Used for caching with 300s TTL

3. **External → App**:
   - Via LoadBalancer service `inventory-service`
   - Port 80 → Container Port 3000
   - NodePort: 31825

---

## Manifest Files

### ✅ Required Manifests (All Created)

1. **deployment.yaml** → [app-deployment.yaml](app-deployment.yaml)
   - Application deployment with 3 replicas
   - HorizontalPodAutoscaler (3-10 replicas)
   - Service definition (LoadBalancer)

2. **service.yaml** → Included in deployment files
   - inventory-service (LoadBalancer)
   - mongodb-service (ClusterIP)
   - redis-service (ClusterIP)

3. **configmap.yaml** → [configmap.yaml](configmap.yaml)
   - Application configuration
   - Database settings
   - Cache settings

4. **secrets.yaml** → [secrets.yaml](secrets.yaml)
   - MongoDB credentials
   - Redis password
   - Created via kubectl (not file)

5. **ingress.yaml** (Optional) → [ingress.yaml](ingress.yaml)
   - Nginx ingress configuration
   - Ready for domain-based routing

---

## Key Features Implemented

### ✅ Production-Ready Features

- **High Availability**: 3 application replicas
- **Auto-Scaling**: HPA based on CPU/Memory (70%/80%)
- **Persistent Storage**: MongoDB (10Gi) and Redis (1Gi) PVCs
- **Health Monitoring**: Liveness and readiness probes
- **Resource Management**: CPU/Memory limits and requests
- **Security**: Secrets for credentials, non-root containers
- **Namespace Isolation**: Dev and Prod environments
- **Service Discovery**: Internal DNS for service-to-service communication
- **Rolling Updates**: Zero-downtime deployment strategy

---

## Deployment Commands

```bash
# 1. Start Minikube
minikube start --memory=3500 --cpus=2

# 2. Build image in Minikube
eval $(minikube docker-env)
docker build -t inventory-manager:latest .

# 3. Create namespaces
kubectl apply -f k8s/namespace-dev.yaml
kubectl apply -f k8s/namespace-prod.yaml

# 4. Create secrets
kubectl create secret generic inventory-secrets \
  --namespace=inventory-prod \
  --from-literal=mongo-username=admin \
  --from-literal=mongo-password=mongopass123 \
  --from-literal=redis-password=redispass123

# 5. Deploy everything
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/persistent-volumes.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml
```

---

## Access Application

```bash
# Get service URL
minikube service inventory-service -n inventory-prod --url

# Or use port-forward
kubectl port-forward svc/inventory-service -n inventory-prod 8080:80
# Access: http://localhost:8080
```

---

## Success Metrics

| Requirement | Status |
|------------|--------|
| Kubernetes Deployment | ✅ Complete |
| Required Manifests | ✅ All Created |
| App-DB Communication | ✅ Working |
| App-Redis Communication | ✅ Working |
| Namespace Organization | ✅ Dev + Prod |
| Screenshots/Outputs | ✅ All Captured |
| Health Checks | ✅ Configured |
| Persistent Storage | ✅ Configured |
| Service Discovery | ✅ Working |
| API Functionality | ✅ Tested |

---

## Documentation Files

- [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Comprehensive deployment guide
- [README.md](README.md) - Kubernetes setup instructions
- This file - Quick reference with all required outputs

---

**Deployment Status**: ✅ **COMPLETE**  
**Date**: December 17, 2025  
**Cluster**: Minikube  
**Namespace**: inventory-prod  
**Application Status**: Running and Responding
