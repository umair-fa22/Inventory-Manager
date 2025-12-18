# Monitoring Configuration

This directory contains configuration files for the monitoring stack (Prometheus, Grafana, Node Exporter).

## Directory Structure

```
monitoring/
├── prometheus.yml                      # Prometheus scrape configuration
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yaml       # Grafana Prometheus datasource
│       └── dashboards/
│           ├── dashboards.yaml        # Dashboard provider config
│           └── inventory-dashboard.json # Pre-built dashboard
└── README.md                          # This file
```

## Files

### prometheus.yml
Main Prometheus configuration file defining:
- Global settings (scrape interval, evaluation interval)
- Scrape configurations for all targets:
  - Prometheus itself
  - Inventory Manager application
  - Node Exporter
  - Kubernetes API, nodes, and pods (when running in K8s)

**Used by:**
- Docker Compose: Mounted as volume
- Kubernetes: Embedded in ConfigMap

### grafana/provisioning/datasources/datasources.yaml
Configures Prometheus as the default Grafana data source.

**Configuration:**
- Data source: Prometheus
- URL: http://prometheus:9090 (service name)
- Access: Server (proxy)
- Auto-provisioned on Grafana startup

### grafana/provisioning/dashboards/dashboards.yaml
Defines where Grafana should look for dashboard JSON files.

**Configuration:**
- Provider: file-based
- Path: `/etc/grafana/provisioning/dashboards/`
- Auto-refresh: 10 seconds
- UI updates: Allowed

### grafana/provisioning/dashboards/inventory-dashboard.json
Pre-built Grafana dashboard for Inventory Manager with panels for:
1. Total Inventory Items (Stat)
2. Request Rate (Time Series)
3. Error Rate (Gauge)
4. Request Latency (Time Series - 95th/50th percentile)
5. Cache Performance (Time Series)
6. CPU Usage (Time Series)
7. Memory Usage (Time Series)
8. Database Errors (Stat)

**Dashboard ID:** `inventory-manager`

## Usage

### Docker Compose

The files are automatically mounted as volumes:

```yaml
prometheus:
  volumes:
    - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  volumes:
    - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
```

### Kubernetes

Configuration is embedded in ConfigMaps:

```bash
kubectl apply -f k8s/prometheus-deployment.yaml  # Contains prometheus.yml in ConfigMap
kubectl apply -f k8s/grafana-deployment.yaml     # Contains all Grafana config in ConfigMaps
```

## Customization

### Adding New Scrape Targets

Edit `prometheus.yml` and add a new job:

```yaml
scrape_configs:
  - job_name: 'my-new-service'
    static_configs:
      - targets: ['my-service:port']
```

Then restart Prometheus:
```bash
# Docker
docker-compose restart prometheus

# Kubernetes
kubectl rollout restart -n monitoring deployment/prometheus
```

### Modifying Dashboard

1. **Via Grafana UI:**
   - Open dashboard in Grafana
   - Make changes
   - Save dashboard
   - Export JSON (Settings → JSON Model)
   - Replace `inventory-dashboard.json`

2. **Direct JSON Edit:**
   - Edit `inventory-dashboard.json`
   - Reload Grafana or wait for auto-refresh

### Adding New Dashboards

1. Create new JSON file in `grafana/provisioning/dashboards/`
2. Restart Grafana or wait for auto-provisioning

## Validation

### Check Prometheus Config

```bash
# Docker
docker exec inventory-prometheus promtool check config /etc/prometheus/prometheus.yml

# Download promtool
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
tar xvf prometheus-2.48.0.linux-amd64.tar.gz
./prometheus-2.48.0.linux-amd64/promtool check config monitoring/prometheus.yml
```

### Verify Scrape Targets

Visit Prometheus UI → Status → Targets
- All targets should show "UP"
- Last scrape should be < 30s ago

### Test Dashboard JSON

Use Grafana's JSON validator:
- Grafana UI → Dashboards → Import
- Paste JSON content
- Verify no errors

## Metrics Retention

Default retention: **30 days**

To change:
- **Docker:** Edit `docker-compose.yml` → prometheus command args
- **Kubernetes:** Edit `k8s/prometheus-deployment.yaml` → args

```yaml
args:
  - '--storage.tsdb.retention.time=60d'  # Change to 60 days
```

## Security Notes

⚠️ **Important:**
- Default Grafana password is `admin123` - **CHANGE IN PRODUCTION**
- Prometheus has no authentication by default
- In production, use:
  - OAuth/LDAP for Grafana
  - Reverse proxy with auth for Prometheus
  - TLS certificates for all services

## Related Documentation

- [MONITORING.md](../MONITORING.md) - Complete monitoring setup guide
- [MONITORING_QUICKSTART.md](../MONITORING_QUICKSTART.md) - Quick reference
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
