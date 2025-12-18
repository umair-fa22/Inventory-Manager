# Monitoring & Observability Setup

## Overview

This document describes the monitoring and observability setup for the Inventory Manager application using **Prometheus** for metrics collection and **Grafana** for visualization.

## Architecture

```
┌─────────────────────┐
│  Inventory App      │
│  (Flask + Metrics)  │◄──┐
└─────────────────────┘   │
                          │ Scrape
┌─────────────────────┐   │ Metrics
│  Node Exporter      │◄──┤
│  (System Metrics)   │   │
└─────────────────────┘   │
                          │
┌─────────────────────┐   │
│   Prometheus        │───┘
│  (Metrics Storage)  │
└─────────────────────┘
           │
           │ Query
           ▼
┌─────────────────────┐
│     Grafana         │
│  (Visualization)    │
└─────────────────────┘
```

## Components

### 1. Prometheus
- **Version:** v2.48.0
- **Purpose:** Collects and stores time-series metrics
- **Port:** 9090
- **Retention:** 30 days
- **Configuration:** `monitoring/prometheus.yml`

### 2. Grafana
- **Version:** 10.2.2
- **Purpose:** Visualizes metrics with dashboards
- **Port:** 3000 (Kubernetes: NodePort 30300, Docker: 3001)
- **Default Credentials:**
  - Username: `admin`
  - Password: `admin123`

### 3. Node Exporter
- **Version:** v1.7.0
- **Purpose:** Exports system-level metrics (CPU, memory, disk, network)
- **Port:** 9100

## Metrics Collected

### Application Metrics

| Metric Name | Type | Description |
|------------|------|-------------|
| `inventory_requests_total` | Counter | Total number of HTTP requests by method, endpoint, and status |
| `inventory_request_duration_seconds` | Histogram | Request latency in seconds |
| `inventory_items_total` | Gauge | Total number of inventory items in database |
| `inventory_cache_hits_total` | Counter | Total number of Redis cache hits |
| `inventory_cache_misses_total` | Counter | Total number of Redis cache misses |
| `inventory_db_errors_total` | Counter | Total number of database errors |

### System Metrics (via Node Exporter)

- **CPU:** Usage percentage, load average
- **Memory:** Total, used, available, buffers, cache
- **Disk:** Usage, I/O operations, read/write rates
- **Network:** Bytes received/transmitted, packet rates

## Deployment

### Docker Compose (Local Development)

1. **Start all services:**
   ```bash
   docker-compose up -d
   ```

2. **Access the services:**
   - **Application:** http://localhost:3000
   - **Prometheus:** http://localhost:9090
   - **Grafana:** http://localhost:3001
   - **Node Exporter:** http://localhost:9100/metrics

3. **Stop services:**
   ```bash
   docker-compose down
   ```

### Kubernetes (Production)

1. **Deploy monitoring namespace and services:**
   ```bash
   kubectl apply -f k8s/prometheus-deployment.yaml
   kubectl apply -f k8s/grafana-deployment.yaml
   ```

2. **Verify deployments:**
   ```bash
   kubectl get pods -n monitoring
   kubectl get svc -n monitoring
   ```

3. **Access the services:**
   
   **Prometheus:**
   ```bash
   # NodePort
   kubectl get nodes -o wide  # Get node IP
   # Access: http://<NODE_IP>:30090
   
   # Or port-forward
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   # Access: http://localhost:9090
   ```

   **Grafana:**
   ```bash
   # NodePort
   # Access: http://<NODE_IP>:30300
   
   # Or port-forward
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   # Access: http://localhost:3000
   ```

## Grafana Dashboard

### Pre-configured Dashboard

The **Inventory Manager Dashboard** includes the following panels:

1. **Total Inventory Items** - Current count of items in database
2. **Request Rate** - Requests per second by endpoint and status
3. **Error Rate** - Rate of 4xx and 5xx errors
4. **Request Latency** - 50th and 95th percentile response times
5. **Cache Performance** - Cache hits vs misses
6. **CPU Usage** - System CPU utilization
7. **Memory Usage** - System memory consumption
8. **Database Errors** - Total database error count

### Accessing the Dashboard

1. Login to Grafana with default credentials:
   - Username: `admin`
   - Password: `admin123`

2. Navigate to **Dashboards** → **Browse**

3. Open **Inventory Manager Dashboard**

4. The dashboard auto-refreshes every 10 seconds

### Creating Custom Dashboards

1. Click **+** → **Dashboard** → **Add visualization**
2. Select **Prometheus** as data source
3. Enter PromQL query (examples below)
4. Configure visualization settings
5. Save dashboard

## PromQL Query Examples

### Application Performance

```promql
# Request rate by endpoint
rate(inventory_requests_total[5m])

# Average response time
rate(inventory_request_duration_seconds_sum[5m]) / rate(inventory_request_duration_seconds_count[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m]))

# Error rate percentage
sum(rate(inventory_requests_total{status=~"4..|5.."}[5m])) / sum(rate(inventory_requests_total[5m])) * 100

# Cache hit ratio
inventory_cache_hits_total / (inventory_cache_hits_total + inventory_cache_misses_total) * 100
```

### System Resources

```promql
# CPU usage percentage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk usage percentage
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100

# Network traffic (bytes/sec)
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

## Alerting (Optional)

### Configure Alertmanager

1. Create `monitoring/alertmanager.yml`:
   ```yaml
   global:
     resolve_timeout: 5m

   route:
     group_by: ['alertname']
     group_wait: 10s
     group_interval: 10s
     repeat_interval: 1h
     receiver: 'email'

   receivers:
     - name: 'email'
       email_configs:
         - to: 'alerts@example.com'
           from: 'prometheus@example.com'
           smarthost: 'smtp.gmail.com:587'
           auth_username: 'your-email@gmail.com'
           auth_password: 'your-app-password'
   ```

2. Create alert rules in `monitoring/alert-rules.yml`:
   ```yaml
   groups:
     - name: inventory_alerts
       rules:
         - alert: HighErrorRate
           expr: sum(rate(inventory_requests_total{status=~"5.."}[5m])) > 10
           for: 5m
           labels:
             severity: critical
           annotations:
             summary: "High error rate detected"
             description: "Error rate is {{ $value }} req/s"

         - alert: HighLatency
           expr: histogram_quantile(0.95, rate(inventory_request_duration_seconds_bucket[5m])) > 1
           for: 5m
           labels:
             severity: warning
           annotations:
             summary: "High response latency"
             description: "95th percentile latency is {{ $value }}s"

         - alert: LowCacheHitRate
           expr: rate(inventory_cache_hits_total[5m]) / (rate(inventory_cache_hits_total[5m]) + rate(inventory_cache_misses_total[5m])) < 0.5
           for: 10m
           labels:
             severity: warning
           annotations:
             summary: "Low cache hit rate"
             description: "Cache hit rate is {{ $value | humanizePercentage }}"
   ```

## Troubleshooting

### Prometheus Not Scraping Targets

1. **Check Prometheus targets:**
   - Navigate to http://localhost:9090/targets
   - Verify all targets are "UP"

2. **Check connectivity:**
   ```bash
   # Docker
   docker exec inventory-prometheus wget -O- http://inventory-app:3000/metrics
   
   # Kubernetes
   kubectl exec -n monitoring deployment/prometheus -- wget -O- http://inventory-app.default.svc:3000/metrics
   ```

3. **Verify app metrics endpoint:**
   ```bash
   curl http://localhost:3000/metrics
   ```

### Grafana Not Showing Data

1. **Check Prometheus data source:**
   - Grafana → Configuration → Data Sources → Prometheus
   - Click "Test" to verify connection

2. **Verify Prometheus has data:**
   ```bash
   # Query Prometheus directly
   curl http://localhost:9090/api/v1/query?query=inventory_requests_total
   ```

3. **Check time range:**
   - Ensure dashboard time range includes recent data
   - Use "Last 5 minutes" for testing

### Node Exporter Not Working

1. **Check if node-exporter is running:**
   ```bash
   # Docker
   docker ps | grep node-exporter
   
   # Kubernetes
   kubectl get pods -n monitoring -l app=node-exporter
   ```

2. **Test node-exporter metrics:**
   ```bash
   curl http://localhost:9100/metrics
   ```

## Best Practices

### 1. Data Retention
- Adjust Prometheus retention based on storage capacity
- Default: 30 days (can be changed in deployment config)
- For longer retention, consider using remote storage (Thanos, Cortex)

### 2. Dashboard Organization
- Create separate dashboards for different concerns:
  - Application performance
  - Infrastructure metrics
  - Business metrics
- Use variables for dynamic filtering
- Set appropriate refresh intervals

### 3. Alert Tuning
- Start with conservative thresholds
- Adjust based on baseline metrics
- Use `for` clause to avoid alert flapping
- Group related alerts

### 4. Security
- Change default Grafana password immediately
- Enable authentication for Prometheus (use reverse proxy)
- Use TLS for all connections in production
- Implement network policies in Kubernetes

### 5. Performance
- Use recording rules for expensive queries
- Limit scrape interval based on needs
- Use appropriate metric types (Counter vs Gauge vs Histogram)
- Implement metric cardinality limits

## Metrics Endpoint Implementation

The Flask application exposes metrics at `/metrics` endpoint using `prometheus_client` library:

```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Metrics definitions
REQUEST_COUNT = Counter('inventory_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('inventory_request_duration_seconds', 'Request latency', ['method', 'endpoint'])
INVENTORY_ITEMS = Gauge('inventory_items_total', 'Total inventory items')
CACHE_HITS = Counter('inventory_cache_hits_total', 'Cache hits')
CACHE_MISSES = Counter('inventory_cache_misses_total', 'Cache misses')
DB_ERRORS = Counter('inventory_db_errors_total', 'Database errors')

# Middleware to track requests
@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    if hasattr(request, 'start_time'):
        latency = time.time() - request.start_time
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.path).observe(latency)
        REQUEST_COUNT.labels(method=request.method, endpoint=request.path, status=response.status_code).inc()
    return response

# Metrics endpoint
@app.route('/metrics')
def metrics():
    INVENTORY_ITEMS.set(collection.count_documents({}))
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
```

## Screenshots

### Expected Dashboard Views

When properly configured, you should see:

1. **Prometheus Targets** (`/targets`):
   - All targets showing "UP" status
   - Last scrape times < 30s

2. **Grafana Home**:
   - Pre-loaded "Inventory Manager Dashboard"
   - Prometheus data source configured

3. **Dashboard Panels**:
   - Real-time graphs updating every 10 seconds
   - Metrics showing actual application traffic
   - CPU/Memory graphs from node-exporter

### Taking Screenshots

For documentation:

1. **Access the application** and generate some traffic:
   ```bash
   # Run load test
   for i in {1..100}; do curl http://localhost:3000/api/items; done
   ```

2. **Open Grafana dashboard** and wait for data to populate (10-30 seconds)

3. **Capture screenshots** of:
   - Full dashboard view
   - Individual panels (Request Rate, Latency, Cache Performance)
   - CPU and Memory usage graphs
   - Prometheus targets page showing all services UP

4. **Save screenshots** to `docs/monitoring-screenshots/` directory:
   - `dashboard-overview.png`
   - `request-metrics.png`
   - `system-metrics.png`
   - `prometheus-targets.png`

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter#enabled-by-default)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)

## Summary

Your monitoring stack is now configured with:

✅ **Prometheus** - Collecting metrics from app and system  
✅ **Grafana** - Visualizing metrics with pre-built dashboard  
✅ **Node Exporter** - Providing system-level metrics  
✅ **Custom Metrics** - Tracking app performance, cache, errors  
✅ **Docker Compose** - Local development setup  
✅ **Kubernetes** - Production-ready deployment  

Access your monitoring:
- **Grafana:** http://localhost:3001 (Docker) or http://<NODE_IP>:30300 (K8s)
- **Prometheus:** http://localhost:9090 (Docker) or http://<NODE_IP>:30090 (K8s)

Login to Grafana with `admin` / `admin123` and explore the **Inventory Manager Dashboard**!
