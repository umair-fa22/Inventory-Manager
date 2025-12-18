# Monitoring Quick Reference

## 🚀 Quick Start

### Docker Compose
```bash
# Start all services including monitoring
docker-compose up -d

# Or just monitoring stack
./deploy-monitoring.sh
```

### Kubernetes
```bash
# Deploy monitoring
./deploy-monitoring.sh

# Or manually
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/grafana-deployment.yaml
```

## 📊 Access URLs

| Service | Docker Compose | Kubernetes |
|---------|---------------|------------|
| **Application** | http://localhost:3000 | http://NODE_IP:30080 |
| **Prometheus** | http://localhost:9090 | http://NODE_IP:30090 |
| **Grafana** | http://localhost:3001 | http://NODE_IP:30300 |
| **Node Exporter** | http://localhost:9100 | ClusterIP only |

**Grafana Credentials:** `admin` / `admin123`

## 🎯 Key Metrics

### Application Metrics
- `inventory_requests_total` - Total HTTP requests
- `inventory_request_duration_seconds` - Request latency
- `inventory_items_total` - Current item count
- `inventory_cache_hits_total` - Cache hits
- `inventory_cache_misses_total` - Cache misses
- `inventory_db_errors_total` - Database errors

### System Metrics (Node Exporter)
- `node_cpu_seconds_total` - CPU usage
- `node_memory_*` - Memory metrics
- `node_filesystem_*` - Disk metrics
- `node_network_*` - Network metrics

## 🔍 Common PromQL Queries

```promql
# Request rate (req/sec)
rate(inventory_requests_total[5m])

# Error rate
sum(rate(inventory_requests_total{status=~"5.."}[5m]))

# 95th percentile latency
histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m]))

# Cache hit ratio
inventory_cache_hits_total / (inventory_cache_hits_total + inventory_cache_misses_total)

# CPU usage %
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage %
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

## 🛠️ Troubleshooting

### Check Prometheus Targets
```bash
# Docker
curl http://localhost:9090/targets

# K8s
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Then visit http://localhost:9090/targets
```

### Verify App Metrics
```bash
curl http://localhost:3000/metrics
```

### Check Logs
```bash
# Docker
docker logs inventory-prometheus
docker logs inventory-grafana

# Kubernetes
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana
```

### Restart Services
```bash
# Docker
docker-compose restart prometheus grafana node-exporter

# Kubernetes
kubectl rollout restart -n monitoring deployment/prometheus
kubectl rollout restart -n monitoring deployment/grafana
```

## 📈 Grafana Dashboard

1. Login: http://localhost:3001 (admin/admin123)
2. Navigate: **Dashboards** → **Browse** → **Inventory Manager Dashboard**
3. Dashboard includes:
   - Total Inventory Items
   - Request Rate
   - Error Rate
   - Request Latency
   - Cache Performance
   - CPU & Memory Usage
   - Database Errors

## 🎬 Generate Test Traffic

```bash
# Simple load test
for i in {1..100}; do
    curl -s http://localhost:3000/api/items > /dev/null
    echo "Request $i completed"
done

# With Apache Bench (if installed)
ab -n 1000 -c 10 http://localhost:3000/api/items

# With hey (if installed)
hey -n 1000 -c 10 http://localhost:3000/api/items
```

## 📸 Screenshots to Capture

For documentation, capture these views:

1. **Grafana Dashboard** - Full view showing all panels
2. **Request Metrics** - Request rate and latency graphs
3. **System Metrics** - CPU and memory usage
4. **Prometheus Targets** - Showing all targets UP
5. **Cache Performance** - Cache hits vs misses

Save to: `docs/monitoring-screenshots/`

## 📚 Documentation

- Full guide: [MONITORING.md](MONITORING.md)
- Project docs: [README.MD](README.MD)
- Kubernetes: [k8s/README.md](k8s/README.md)

## ⚡ Quick Commands

```bash
# Deploy monitoring
./deploy-monitoring.sh

# Check status (Docker)
docker-compose ps

# Check status (K8s)
kubectl get all -n monitoring

# View Prometheus config
cat monitoring/prometheus.yml

# Tail logs (Docker)
docker-compose logs -f prometheus grafana

# Port forward Grafana (K8s)
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

---

**Need Help?** See [MONITORING.md](MONITORING.md) for detailed documentation.
