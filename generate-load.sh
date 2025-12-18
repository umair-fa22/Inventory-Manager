#!/bin/bash
# Generate traffic for monitoring metrics

echo "Generating traffic to create metrics..."

# Create some items
for i in {1..30}
do
    price=$((i * 10))
    curl -s -X POST http://localhost:3000/api/items \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Product$i\",\"quantity\":$i,\"price\":$price}" > /dev/null
    
    # Get items occasionally
    if [ $((i % 5)) -eq 0 ]; then
        curl -s http://localhost:3000/api/items > /dev/null
    fi
    
    sleep 0.2
done

echo "✓ Generated 30 POST requests"

# Generate more load
echo "Generating additional GET load..."
for i in {1..50}
do
    curl -s http://localhost:3000/api/items > /dev/null
    curl -s http://localhost:3000/ > /dev/null
    sleep 0.1
done

echo "✓ Total traffic generated successfully"
echo "✓ Check Grafana at http://localhost:3001 (admin/admin123)"
echo "✓ Check Prometheus at http://localhost:9090"
