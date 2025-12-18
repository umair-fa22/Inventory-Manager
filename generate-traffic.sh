#!/bin/bash

# Generate Test Traffic for Monitoring Dashboard
# This script creates HTTP traffic to populate Grafana dashboards

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_URL="${APP_URL:-http://localhost:3000}"
REQUESTS="${REQUESTS:-100}"
CONCURRENT="${CONCURRENT:-10}"

echo "======================================"
echo "Monitoring Traffic Generator"
echo "======================================"
echo ""
echo -e "${BLUE}Target URL:${NC} $APP_URL"
echo -e "${BLUE}Requests:${NC} $REQUESTS"
echo -e "${BLUE}Concurrent:${NC} $CONCURRENT"
echo ""

# Check if app is running
if ! curl -s "$APP_URL" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Warning: Application may not be running at $APP_URL${NC}"
    echo "Make sure the app is started first!"
    exit 1
fi

echo -e "${GREEN}✓ Application is reachable${NC}"
echo ""

# Function to make requests
make_requests() {
    local endpoint=$1
    local method=$2
    local data=$3
    local count=$4
    
    echo -e "${BLUE}Sending $count requests to $endpoint...${NC}"
    
    for i in $(seq 1 $count); do
        if [ "$method" = "POST" ]; then
            curl -s -X POST "$APP_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" > /dev/null 2>&1 || true
        elif [ "$method" = "GET" ]; then
            curl -s "$APP_URL$endpoint" > /dev/null 2>&1 || true
        fi
        
        # Show progress every 10 requests
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    echo ""
    echo -e "${GREEN}✓ Completed $count requests${NC}"
}

echo "Starting traffic generation..."
echo ""

# 1. GET requests to list items
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Fetching inventory items (GET)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
make_requests "/api/items" "GET" "" 40

sleep 1

# 2. Create items
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Creating new items (POST)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

items=(
    '{"name":"Monitor","unitPrice":299.99,"quantity":15}'
    '{"name":"Keyboard","unitPrice":79.99,"quantity":30}'
    '{"name":"Mouse","unitPrice":49.99,"quantity":50}'
    '{"name":"Laptop","unitPrice":1299.99,"quantity":10}'
    '{"name":"Desk","unitPrice":449.99,"quantity":8}'
)

for item in "${items[@]}"; do
    curl -s -X POST "$APP_URL/api/items" \
        -H "Content-Type: application/json" \
        -d "$item" > /dev/null 2>&1 || true
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Created sample items${NC}"

sleep 1

# 3. More GET requests (to test cache hits)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Testing cache performance (GET)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
make_requests "/api/items" "GET" "" 30

sleep 1

# 4. Access metrics endpoint
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Accessing metrics endpoint"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for i in {1..10}; do
    curl -s "$APP_URL/metrics" > /dev/null 2>&1 || true
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Metrics scraped${NC}"

sleep 1

# 5. Generate some errors (invalid endpoints)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Generating error traffic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for i in {1..10}; do
    curl -s "$APP_URL/api/nonexistent" > /dev/null 2>&1 || true
    curl -s "$APP_URL/api/items/invalid-id" > /dev/null 2>&1 || true
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Error traffic generated${NC}"

sleep 1

# 6. Mixed traffic
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Mixed workload"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for i in {1..20}; do
    # Random endpoint
    case $((RANDOM % 3)) in
        0) curl -s "$APP_URL/api/items" > /dev/null 2>&1 || true ;;
        1) curl -s "$APP_URL/" > /dev/null 2>&1 || true ;;
        2) curl -s "$APP_URL/metrics" > /dev/null 2>&1 || true ;;
    esac
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Mixed workload completed${NC}"

# Summary
echo ""
echo "======================================"
echo "Traffic Generation Complete!"
echo "======================================"
echo ""
echo -e "${GREEN}✓${NC} Generated ~150 HTTP requests"
echo -e "${GREEN}✓${NC} Created sample inventory items"
echo -e "${GREEN}✓${NC} Tested cache performance"
echo -e "${GREEN}✓${NC} Generated error traffic"
echo -e "${GREEN}✓${NC} Accessed metrics endpoint"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Check Prometheus metrics:"
echo "   ${BLUE}$APP_URL/metrics${NC}"
echo ""
echo "2. View Prometheus targets:"
echo "   ${BLUE}http://localhost:9090/targets${NC}"
echo ""
echo "3. Open Grafana dashboard:"
echo "   ${BLUE}http://localhost:3001${NC}"
echo "   Login: admin / admin123"
echo ""
echo "4. Navigate to:"
echo "   Dashboards → Browse → Inventory Manager Dashboard"
echo ""
echo "5. You should see populated graphs with:"
echo "   • Request rates"
echo "   • Response latency"
echo "   • Cache performance"
echo "   • Error counts"
echo "   • System metrics (CPU, Memory)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}💡 Tip:${NC} Run this script multiple times to generate more data"
echo ""
