#!/bin/bash

# setup.sh - Automates setup and testing of Prometheus and Grafana monitoring stack

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check for prerequisites
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: Docker is not installed${NC}"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}Error: Docker Compose is not installed${NC}"; exit 1; }
command -v stress >/dev/null 2>&1 || { echo -e "${RED}Warning: stress tool not found. Install it to test alerts (e.g., 'sudo apt install stress' on Ubuntu)${NC}"; }

# Prompt for webhook.site URL
echo "Enter your webhook.site URL for Alertmanager (press Enter to skip for manual setup):"
read -r WEBHOOK_URL
if [ -n "$WEBHOOK_URL" ]; then
    sed -i "s|url: 'https://webhook.site/your-unique-id'|url: '$WEBHOOK_URL'|" alertmanager/alertmanager.yml
    echo -e "${GREEN}Updated alertmanager.yml with webhook URL${NC}"
else
    echo -e "${RED}Webhook URL not provided. Please update alertmanager/alertmanager.yml manually.${NC}"
fi

# Start Docker Compose
echo "Starting monitoring stack..."
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Monitoring stack started successfully${NC}"
else
    echo -e "${RED}Failed to start monitoring stack. Check docker-compose logs.${NC}"
    exit 1
fi

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 10

# Verify services
echo "Checking service availability..."
curl -s http://localhost:9090 >/dev/null && echo -e "${GREEN}Prometheus is up (http://localhost:9090)${NC}" || echo -e "${RED}Prometheus is down${NC}"
curl -s http://localhost:3000 >/dev/null && echo -e "${GREEN}Grafana is up (http://localhost:3000, admin/securepassword123)${NC}" || echo -e "${RED}Grafana is down${NC}"
curl -s http://localhost:9093 >/dev/null && echo -e "${GREEN}Alertmanager is up (http://localhost:9093)${NC}" || echo -e "${RED}Alertmanager is down${NC}"
curl -s http://localhost:9100 >/dev/null && echo -e "${GREEN}Node Exporter is up (http://localhost:9100)${NC}" || echo -e "${RED}Node Exporter is down${NC}"

# Open services in browser (macOS/Linux compatible)
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open http://localhost:3000 & # Grafana
    xdg-open http://localhost:9090 & # Prometheus
    xdg-open http://localhost:9093 & # Alertmanager
elif command -v open >/dev/null 2>&1; then
    open http://localhost:3000 & # Grafana
    open http://localhost:9090 & # Prometheus
    open http://localhost:9093 & # Alertmanager
fi

# Test alert (if stress is installed)
if command -v stress >/dev/null 2>&1; then
    echo "Simulating high CPU usage to trigger alert (runs for 6 minutes)..."
    stress --cpu 2 --timeout 360 &
    echo "Check Prometheus alerts (http://localhost:9090/alerts) and webhook.site after 5 minutes."
else
    echo -e "${RED}Cannot simulate CPU load without stress tool. Install it to test alerts.${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo "Next steps:"
echo "- Import Node Exporter dashboard (ID 1860) in Grafana."
echo "- Monitor alerts in Prometheus and webhook.site."
echo "- To stop the stack, run: docker-compose down"
