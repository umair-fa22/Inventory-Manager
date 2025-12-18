# 📊 Step 7 - Monitoring & Observability Guide

## Quick Start (5 Minutes)

### 1. Deploy Monitoring Stack

```bash
# Option A: Use deployment script
./deploy-monitoring.sh

# Option B: Docker Compose
docker-compose up -d

# Option C: Kubernetes
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/grafana-deployment.yaml
```

### 2. Generate Test Traffic

```bash
./generate-traffic.sh
```

### 3. View Dashboard

1. Open Grafana: http://localhost:3001 (Docker) or http://NODE_IP:30300 (K8s)
2. Login: `admin` / `admin123`
3. Navigate: **Dashboards** → **Browse** → **Inventory Manager Dashboard**

### 4. Capture Screenshots

Open the dashboard and take screenshots showing:
- Full dashboard with all 8 panels
- Request rate and latency graphs
- CPU and memory usage
- Cache performance
- Prometheus targets page (http://localhost:9090/targets)

---

## 🎯 What's Included

### Metrics Collection (Prometheus)
- ✅ Application metrics at `/metrics` endpoint
- ✅ System metrics via Node Exporter
- ✅ Kubernetes metrics (pods, nodes, API)
- ✅ 30-day retention
- ✅ Auto-discovery of targets

### Visualization (Grafana)
- ✅ Pre-configured dashboard with 8 panels
- ✅ Auto-provisioned datasource
- ✅ 10-second auto-refresh
- ✅ Professional layout

### Custom Metrics
| Metric | Description |
|--------|-------------|
| `inventory_requests_total` | Total HTTP requests |
| `inventory_request_duration_seconds` | Request latency |
| `inventory_items_total` | Current item count |
| `inventory_cache_hits_total` | Cache hits |
| `inventory_cache_misses_total` | Cache misses |
| `inventory_db_errors_total` | Database errors |

---

## 📸 Screenshot Checklist

### Required Screenshots for Documentation

#### 1. Grafana Dashboard Overview
**File:** `dashboard-overview.png`

**What to capture:**
- Full dashboard showing all 8 panels
- Data populated from test traffic
- Time range: Last 15 minutes
- All metrics showing non-zero values

**Steps:**
1. Generate traffic: `./generate-traffic.sh`
2. Wait 30 seconds for metrics to propagate
3. Open Grafana dashboard
4. Capture full screen

#### 2. Request Metrics Detail
**File:** `request-metrics.png`

**What to capture:**
- Request Rate panel (Time Series)
- Request Latency panel (95th/50th percentile)
- Both panels showing clear trend lines

**Steps:**
1. Zoom into Request Rate and Latency panels
2. Ensure legend shows multiple endpoints
3. Capture zoomed view

#### 3. System Metrics
**File:** `system-metrics.png`

**What to capture:**
- CPU Usage panel
- Memory Usage panel
- Both showing data from Node Exporter

**Steps:**
1. Focus on CPU and Memory panels
2. Ensure graphs show system load
3. Capture both panels together

#### 4. Prometheus Targets
**File:** `prometheus-targets.png`

**What to capture:**
- All targets showing "UP" status
- Last scrape times
- Scrape duration

**Steps:**
1. Open http://localhost:9090/targets
2. Verify all targets are UP:
   - prometheus (1/1 up)
   - inventory-app (1/1 up)
   - node-exporter (1/1 up)
3. Capture full page

#### 5. Cache Performance
**File:** `cache-performance.png`

**What to capture:**
- Cache Performance panel
- Both cache hits and misses lines
- Legend showing values

**Steps:**
1. Focus on Cache Performance panel
2. Ensure both metrics are visible
3. Capture panel with legend

---

## 🧪 Testing & Verification

### 1. Verify Metrics Endpoint

```bash
curl http://localhost:3000/metrics | head -20
```

**Expected output:**
```
# HELP inventory_requests_total Total number of requests
# TYPE inventory_requests_total counter
inventory_requests_total{endpoint="/api/items",method="GET",status="200"} 42.0
...
```

### 2. Check Prometheus Scraping

```bash
# Check if Prometheus is scraping the app
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="inventory-app") | .health'
```

**Expected:** `"up"`

### 3. Verify Grafana Dashboard

```bash
# Test Grafana API
curl -u admin:admin123 http://localhost:3001/api/dashboards/uid/inventory-manager
```

**Expected:** JSON with dashboard definition

### 4. Test Queries

Open Prometheus UI (http://localhost:9090) and run:

```promql
# Request rate
rate(inventory_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m]))

# Cache hit ratio
inventory_cache_hits_total / (inventory_cache_hits_total + inventory_cache_misses_total)
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| [MONITORING.md](MONITORING.md) | Complete setup and configuration guide |
| [MONITORING_QUICKSTART.md](MONITORING_QUICKSTART.md) | Quick reference for common tasks |
| [STEP7_MONITORING_SUMMARY.md](STEP7_MONITORING_SUMMARY.md) | Implementation summary and checklist |
| [monitoring/README.md](monitoring/README.md) | Configuration file documentation |

---

## 🔧 Troubleshooting

### Prometheus Not Scraping App

**Problem:** Targets showing "DOWN"

**Solution:**
```bash
# Docker: Check connectivity
docker exec inventory-prometheus wget -O- http://inventory-app:3000/metrics

# Check app logs
docker logs inventory-app

# Restart Prometheus
docker-compose restart prometheus
```

### Grafana Dashboard Empty

**Problem:** No data in panels

**Solution:**
```bash
# 1. Generate traffic
./generate-traffic.sh

# 2. Check Prometheus has data
curl http://localhost:9090/api/v1/query?query=inventory_requests_total

# 3. Verify datasource
# Grafana → Configuration → Data Sources → Prometheus → Test

# 4. Adjust time range
# Dashboard → Time range → Last 5 minutes
```

### Node Exporter Not Working

**Problem:** System metrics missing

**Solution:**
```bash
# Docker: Check container
docker ps | grep node-exporter

# Test metrics
curl http://localhost:9100/metrics | head -10

# Restart if needed
docker-compose restart node-exporter
```

---

## 🚀 Advanced Usage

### Custom Queries

Add to Grafana dashboard:

```promql
# Error rate percentage
sum(rate(inventory_requests_total{status=~"4..|5.."}[5m])) / sum(rate(inventory_requests_total[5m])) * 100

# Average response time
rate(inventory_request_duration_seconds_sum[5m]) / rate(inventory_request_duration_seconds_count[5m])

# Top slowest endpoints
topk(5, histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m])))
```

### Alert Rules

Create `monitoring/alert-rules.yml`:

```yaml
groups:
  - name: inventory_alerts
    rules:
      - alert: HighErrorRate
        expr: sum(rate(inventory_requests_total{status=~"5.."}[5m])) > 10
        for: 5m
        annotations:
          summary: "High error rate detected"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        annotations:
          summary: "High response latency"
```

### Load Testing

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Run load test
hey -n 10000 -c 50 -q 10 http://localhost:3000/api/items

# Watch metrics in real-time
watch -n 1 'curl -s http://localhost:3000/metrics | grep inventory_requests_total'
```

---

## ✅ Completion Checklist

Before marking Step 7 complete:

- [ ] Monitoring stack deployed (Prometheus + Grafana + Node Exporter)
- [ ] Application exposing metrics at `/metrics`
- [ ] Prometheus successfully scraping all targets (all UP)
- [ ] Grafana dashboard accessible and showing data
- [ ] Test traffic generated to populate graphs
- [ ] Screenshots captured:
  - [ ] Dashboard overview
  - [ ] Request metrics
  - [ ] System metrics (CPU/Memory)
  - [ ] Prometheus targets
  - [ ] Cache performance
- [ ] Documentation reviewed
- [ ] All metrics showing expected values

---

## 📊 Expected Dashboard View

When complete, your Grafana dashboard should show:

1. **Total Inventory Items**: Non-zero count (5-10 items from test traffic)
2. **Request Rate**: Graph showing spikes during traffic generation
3. **Error Rate**: Low (green) with occasional spikes from invalid requests
4. **Request Latency**: 95th percentile < 100ms, 50th percentile < 50ms
5. **Cache Performance**: Rising lines for both hits and misses
6. **CPU Usage**: 0-30% depending on system load
7. **Memory Usage**: Stable line showing used memory
8. **Database Errors**: 0 (green)

---

## 🎓 Next Steps

After completing Step 7:

### Optional Enhancements
1. **Alerting** - Configure Alertmanager for notifications
2. **Extended Retention** - Set up Thanos or remote storage
3. **Additional Exporters** - MongoDB, Redis exporters
4. **Custom Dashboards** - Create business-specific views
5. **SLO/SLI Tracking** - Define and monitor service levels

### Integration with CI/CD
```yaml
# Add to Jenkinsfile
stage('Monitor Deployment') {
    steps {
        sh './deploy-monitoring.sh'
        sh './generate-traffic.sh'
        sh 'curl http://localhost:3000/metrics | grep -q inventory_requests_total'
    }
}
```

---

## 📞 Support Resources

- **Documentation**: [MONITORING.md](MONITORING.md)
- **Quick Reference**: [MONITORING_QUICKSTART.md](MONITORING_QUICKSTART.md)
- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Docs**: https://grafana.com/docs/

---

## Summary

Step 7 provides comprehensive monitoring with:
- ✅ **Prometheus** collecting metrics from app and system
- ✅ **Grafana** visualizing performance in real-time
- ✅ **Custom metrics** tracking app behavior
- ✅ **System metrics** monitoring CPU, memory, disk, network
- ✅ **Pre-built dashboard** ready to use
- ✅ **Automation scripts** for easy deployment
- ✅ **Complete documentation** for reference

**Your monitoring stack is production-ready!** 🎉
