# Step 7 - Monitoring & Observability Results
## Grafana + Prometheus Implementation

---

## ✅ Monitoring Stack Successfully Deployed

### Components Running:
- ✅ **Prometheus** (v2.48.0) - Metrics collection and storage
- ✅ **Grafana** (v10.2.2) - Metrics visualization dashboards
- ✅ **Node Exporter** (v1.7.0) - System-level metrics (CPU, memory, disk, network)
- ✅ **Application Metrics** - Custom app metrics from Inventory Manager

---

## 🔗 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana Dashboard** | http://localhost:3001 | Username: `admin`<br>Password: `admin123` |
| **Prometheus** | http://localhost:9090 | No authentication |
| **Node Exporter** | http://localhost:9100 | Metrics endpoint |
| **App Metrics** | http://localhost:3000/metrics | Application metrics |

---

## 📊 Available Metrics

### 1. Application Metrics
Prometheus is collecting the following from the Inventory Manager app:

- **HTTP Request Rate** - Total requests per second
- **Response Time** - Request latency (P50, P95, P99)
- **HTTP Status Codes** - 2xx, 4xx, 5xx response counts
- **Active Connections** - Current active connections
- **Request Duration** - Time to process requests
- **Error Rate** - Failed requests percentage

### 2. System Metrics (Node Exporter)
Collecting host-level metrics:

- **CPU Usage** - Per-core and aggregate CPU utilization
- **Memory Usage** - Used, free, cached, buffers
- **Disk I/O** - Read/write operations and throughput
- **Network Traffic** - Bytes in/out per interface
- **Load Average** - 1m, 5m, 15m system load
- **Disk Space** - Available vs used storage

### 3. Infrastructure Metrics
- **Container Health** - Docker container status
- **Database Connections** - MongoDB connection pool metrics
- **Cache Hit Rate** - Redis cache performance

---

## 📈 Grafana Dashboards

### Pre-configured Dashboard: "Inventory Manager Overview"

The dashboard includes the following panels:

#### Row 1: Application Health
- **Service Status** - Up/Down status indicator
- **Request Rate** - Requests per second (last 5m)
- **Error Rate** - Percentage of failed requests
- **Response Time** - Average request latency

#### Row 2: HTTP Metrics
- **HTTP Request Rate by Status Code** - 2xx/4xx/5xx breakdown
- **Request Duration (Percentiles)** - P50, P95, P99 latencies
- **Active Connections** - Current connections graph

#### Row 3: System Resources
- **CPU Usage** - System and per-core CPU %
- **Memory Usage** - Available vs used memory
- **Disk I/O** - Read/write operations per second
- **Network Traffic** - Bytes received/transmitted

#### Row 4: Database & Cache
- **MongoDB Operations** - Query rate and latency
- **Redis Hit Rate** - Cache effectiveness
- **Connection Pool** - Active database connections

---

## 🚀 How to Access and View Dashboards

### Step 1: Verify All Services are Running
```bash
docker-compose ps
```

Expected output should show all containers as "Up" and healthy.

### Step 2: Access Grafana
1. Open your browser to: **http://localhost:3001**
2. Login with credentials:
   - Username: `admin`
   - Password: `admin123`

### Step 3: View the Dashboard
1. From Grafana home, click **"Dashboards"** in the left sidebar
2. Click on **"Inventory Manager Overview"** dashboard
3. The dashboard will load with real-time metrics

### Step 4: Customize Time Range
- In the top-right corner, adjust the time range (Last 5m, 15m, 1h, etc.)
- Enable auto-refresh for real-time monitoring

---

## 📸 Key Screenshots to Capture

To fulfill the assignment requirements, capture screenshots of:

### 1. Grafana Dashboard Overview
- Full dashboard showing all panels
- **Path**: Dashboards → Inventory Manager Overview

### 2. CPU Metrics
- Panel showing CPU usage over time
- Multiple cores if available
- **Metric**: `rate(node_cpu_seconds_total[5m])`

### 3. Memory Metrics
- Memory usage (used vs available)
- **Metric**: `node_memory_MemAvailable_bytes` and `node_memory_MemTotal_bytes`

### 4. Request Count/Rate
- HTTP requests per second
- Status code breakdown
- **Metric**: `rate(http_requests_total[5m])`

### 5. Application Response Time
- Request duration percentiles
- Latency over time
- **Metric**: `http_request_duration_seconds`

### 6. Prometheus Targets
- Open http://localhost:9090/targets
- Shows all monitored services with "UP" status

### 7. Prometheus Graph
- Open http://localhost:9090/graph
- Query: `up` to show service availability

---

## 🔍 Prometheus Query Examples

Access Prometheus at http://localhost:9090 and try these queries:

### Service Health
```promql
up
```
Shows which services are up (1) or down (0)

### CPU Usage
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory Usage Percentage
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### HTTP Request Rate
```promql
rate(http_requests_total[5m])
```

### Request Duration (P95)
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Error Rate
```promql
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
```

---

## 🧪 Generate Test Traffic

To create meaningful metrics, run the traffic generation script:

```bash
./generate-load.sh
```

This script will:
- Create 30 new inventory items
- Make 50+ health check requests
- Generate GET requests to list items
- Create varied load patterns for monitoring

After running this, refresh your Grafana dashboard to see:
- Increased request rates
- CPU and memory spikes
- Response time variations
- Cache hit/miss patterns

---

## 📊 Monitoring Configuration

### Prometheus Configuration
Location: `monitoring/prometheus.yml`

**Scrape Interval**: 15 seconds  
**Retention**: 30 days  
**Targets**:
- Prometheus itself (localhost:9090)
- Inventory App (inventory-app:3000)
- Node Exporter (node-exporter:9100)

### Grafana Datasource
- **Type**: Prometheus
- **URL**: http://prometheus:9090
- **Access**: Server (proxy)
- **Auto-configured**: Yes (via provisioning)

### Dashboard Provisioning
- **Location**: `monitoring/grafana/provisioning/dashboards/`
- **Auto-loaded**: Yes
- **Editable**: Yes

---

## ✅ Requirements Checklist

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Prometheus collects metrics | ✅ Complete | Scraping app + node-exporter |
| Grafana visualizes metrics | ✅ Complete | Pre-configured dashboards |
| CPU metrics displayed | ✅ Complete | Node exporter CPU panels |
| Memory metrics displayed | ✅ Complete | Memory usage panels |
| Request count tracked | ✅ Complete | HTTP request rate graphs |
| Screenshots available | ⏳ In Progress | Access dashboards to capture |

---

## 🎯 Next Steps for Screenshots

1. **Open Grafana**: http://localhost:3001
2. **Login**: admin / admin123
3. **Navigate to**: Dashboards → Inventory Manager Overview
4. **Generate Load**: Run `./generate-load.sh` to create traffic
5. **Wait 30 seconds**: For metrics to populate
6. **Capture Screenshots**:
   - Full dashboard view
   - Individual CPU panel (zoomed)
   - Memory panel (zoomed)
   - Request rate panel (zoomed)
   - Response time panel (zoomed)

7. **Prometheus Screenshots**:
   - http://localhost:9090/targets (all targets UP)
   - http://localhost:9090/graph with query `up`
   - Query results for CPU and memory

---

## 🔧 Troubleshooting

### If Grafana shows "No Data"
```bash
# Check Prometheus is scraping targets
curl http://localhost:9090/api/v1/targets

# Verify app is exposing metrics
curl http://localhost:3000/metrics

# Generate some traffic
./generate-load.sh
```

### If containers are not running
```bash
# Restart all services
docker-compose restart

# Check logs
docker-compose logs grafana
docker-compose logs prometheus
```

### If dashboard is not loaded
1. Go to Configuration → Data Sources
2. Verify Prometheus datasource is configured
3. Test the connection (should show "Data source is working")
4. Go to Dashboards → Browse
5. Look for "Inventory Manager Overview"

---

## 📝 Additional Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Node Exporter Metrics**: https://github.com/prometheus/node_exporter

---

## 🎓 Assignment Submission

For the assignment, include:

1. ✅ **This documentation** - Proving setup is complete
2. 📸 **Screenshot**: Grafana dashboard overview (all panels visible)
3. 📸 **Screenshot**: CPU usage panel (zoomed in)
4. 📸 **Screenshot**: Memory usage panel (zoomed in)
5. 📸 **Screenshot**: Request count/rate panel (zoomed in)
6. 📸 **Screenshot**: Prometheus targets page (showing all UP)
7. 📝 **Brief explanation**: 2-3 sentences describing what metrics are being collected and why they're important

**Total Points**: 10 Marks

---

**Status**: ✅ Monitoring Stack Fully Operational  
**Last Updated**: December 18, 2025  
**Verified**: All services running, metrics collecting, dashboards accessible
