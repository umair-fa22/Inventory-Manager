# Screenshot Capture Guide for Step 7 - Monitoring
## Quick Reference for Assignment Submission

---

## 📸 Required Screenshots (6 Total)

### Screenshot 1: Grafana Dashboard Overview
**What to capture**: Full Grafana dashboard showing all monitoring panels

**Steps**:
1. Open browser to: `http://localhost:3001`
2. Login: username=`admin`, password=`admin123`
3. Navigate to: **Dashboards** → **Inventory Manager Overview**
4. Wait for all panels to load (30 seconds)
5. Take full-screen screenshot showing:
   - Service health indicators
   - Request rate graphs
   - CPU/Memory metrics
   - Network traffic

**File name**: `grafana_dashboard_overview.png`

---

### Screenshot 2: CPU Usage Panel
**What to capture**: Detailed CPU utilization metrics

**Steps**:
1. On the Grafana dashboard, locate the **"CPU Usage"** panel
2. Click on the panel title → **View**
3. This opens the panel in full-screen mode
4. Capture showing:
   - CPU percentage over time
   - Per-core breakdown (if available)
   - Legend with metric names

**Alternative**: In Prometheus
- URL: `http://localhost:9090/graph`
- Query: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Switch to **Graph** tab
- Take screenshot

**File name**: `cpu_metrics.png`

---

### Screenshot 3: Memory Usage Panel
**What to capture**: Memory consumption metrics

**Steps**:
1. On the Grafana dashboard, locate the **"Memory Usage"** panel
2. Click panel title → **View** for full-screen
3. Capture showing:
   - Used vs Available memory
   - Memory percentage over time
   - Memory breakdown (cached, buffers, free)

**Alternative**: In Prometheus
- URL: `http://localhost:9090/graph`
- Query: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- Switch to **Graph** tab
- Take screenshot

**File name**: `memory_metrics.png`

---

### Screenshot 4: Request Count/Rate
**What to capture**: HTTP request metrics showing application traffic

**Steps**:
1. On the Grafana dashboard, locate **"HTTP Request Rate"** panel
2. Click panel title → **View** for full-screen
3. Capture showing:
   - Requests per second graph
   - Color-coded by status code (2xx, 4xx, 5xx)
   - Time series showing traffic patterns

**Alternative**: In Prometheus
- URL: `http://localhost:9090/graph`
- Query: `rate(http_requests_total[5m])`
- Switch to **Graph** tab
- Take screenshot

**File name**: `request_count.png`

---

### Screenshot 5: Response Time/Latency
**What to capture**: Application performance metrics

**Steps**:
1. On Grafana dashboard, locate **"Request Duration"** or **"Response Time"** panel
2. Click panel title → **View**
3. Capture showing:
   - Response time graph over time
   - P50, P95, P99 percentiles (if available)
   - Latency trends

**Alternative**: In Prometheus
- URL: `http://localhost:9090/graph`
- Query: `rate(process_cpu_seconds_total[5m])`
- Switch to **Graph** tab
- Take screenshot

**File name**: `response_time.png`

---

### Screenshot 6: Prometheus Targets Status
**What to capture**: All monitoring targets showing "UP" status

**Steps**:
1. Open browser to: `http://localhost:9090/targets`
2. This shows all services being monitored
3. Capture showing:
   - All targets with "UP" state (green)
   - Target endpoints
   - Last scrape time
   - Should show: inventory-app, node-exporter, prometheus

**File name**: `prometheus_targets.png`

---

## 🎬 Before Taking Screenshots

Run this to ensure metrics are populated:

```bash
# Generate traffic for interesting metrics
./generate-load.sh

# Wait 30 seconds for metrics to be collected
sleep 30
```

---

## 📋 Quick Checklist

- [ ] All 6 containers running (check: `docker-compose ps`)
- [ ] Generated test traffic (`./generate-load.sh`)
- [ ] Waited 30+ seconds for metrics collection
- [ ] Grafana accessible at http://localhost:3001
- [ ] Prometheus accessible at http://localhost:9090
- [ ] Dashboard loaded with data (not showing "No Data")
- [ ] Screenshot 1: Grafana full dashboard
- [ ] Screenshot 2: CPU metrics
- [ ] Screenshot 3: Memory metrics
- [ ] Screenshot 4: Request count/rate
- [ ] Screenshot 5: Response time/latency
- [ ] Screenshot 6: Prometheus targets page

---

## 🔍 What Each Screenshot Demonstrates

| Screenshot | Demonstrates | Points Value |
|-----------|--------------|--------------|
| Dashboard Overview | Complete monitoring setup | 2 marks |
| CPU Metrics | System resource monitoring | 2 marks |
| Memory Metrics | Resource utilization tracking | 2 marks |
| Request Count | Application traffic monitoring | 2 marks |
| Response Time | Performance metrics collection | 1 mark |
| Prometheus Targets | Metrics collection architecture | 1 mark |

**Total**: 10 marks

---

## 💡 Tips for Best Screenshots

1. **Full Screen**: Use F11 for full-screen browser
2. **Time Range**: Set to "Last 5 minutes" for active data
3. **Refresh**: Enable auto-refresh (top-right in Grafana)
4. **Zoom**: Make sure text is readable
5. **Clean Up**: Close unnecessary browser tabs/windows
6. **Annotations**: Use arrows or highlights if needed

---

## 🚨 Troubleshooting

### "No Data" in Grafana panels
```bash
# Check if Prometheus is scraping
curl http://localhost:9090/api/v1/targets

# Verify app metrics endpoint
curl http://localhost:3000/metrics

# Restart services if needed
docker-compose restart grafana prometheus
```

### Can't access Grafana
```bash
# Check if container is running
docker ps | grep grafana

# Check logs
docker-compose logs grafana

# Restart
docker-compose restart grafana
```

### Prometheus shows targets DOWN
```bash
# Check network connectivity
docker-compose exec prometheus wget -O- http://inventory-app:3000/metrics

# Restart all
docker-compose restart
```

---

## 📤 Submission Checklist

Include in your assignment submission:

1. ✅ **STEP7_MONITORING_RESULTS.md** - Complete documentation
2. 📸 **grafana_dashboard_overview.png** - Full dashboard view
3. 📸 **cpu_metrics.png** - CPU usage graph
4. 📸 **memory_metrics.png** - Memory usage graph
5. 📸 **request_count.png** - HTTP request rate
6. 📸 **response_time.png** - Application latency
7. 📸 **prometheus_targets.png** - Monitoring targets status
8. 📝 **Brief explanation** (2-3 sentences) describing the monitoring setup

---

**Ready?** Follow the steps above to capture all required screenshots! 🎯
