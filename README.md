# Monitoring Stack with Prometheus and Grafana

This repository provides a Dockerized monitoring and alerting system using **Prometheus**, **Grafana**, **Node Exporter**, and **Alertmanager**. It monitors system metrics (CPU, memory, disk) and triggers alerts for high CPU usage, visualized through a Grafana dashboard. The setup is automated with a Bash script (`setup.sh`) for easy deployment and testing, designed for a DevOps technical challenge.

## Features

- **Prometheus**: Scrapes metrics from Node Exporter (system metrics) and itself.
- **Grafana**: Visualizes metrics via the Node Exporter Full dashboard (ID 1860).
- **Alertmanager**: Sends alerts for high CPU usage (>80% for 5 minutes) to a webhook (e.g., webhook.site).
- **Node Exporter**: Collects system-level metrics.
- **Docker Compose**: Orchestrates services with a dedicated `monitoring` network for isolation.
- **Automation**: `setup.sh` script automates setup, webhook configuration, and alert testing.
- **Security**: Grafana is secured with credentials; Prometheus is unsecured for local testing but isolated via Docker network.

## Repository Structure
``` text
monitoring-stack/
├── docker-compose.yml # Orchestrates Prometheus, Grafana, Node Exporter, Alertmanager
├── prometheus/
│ ├── prometheus.yml # Prometheus configuration for scraping
│ └── alerts.yml # Alert rule for high CPU usage
├── alertmanager/
│ └── alertmanager.yml # Alertmanager configuration with webhook receiver
├── grafana/
│ ├── provisioning/
│ │ └── datasources/
│ │ └── datasource.yml # Provisions Prometheus as Grafana data source
│ └── dashboards/ # Optional: Place for dashboard JSON
├── setup.sh # Script to automate setup and testing
├── README.md # This file
└── .gitignore # Ignores logs and temporary files
```
## Prerequisites

- **Docker** and **Docker Compose**.
- **stress** tool (optional, for alert testing):
  - Ubuntu/Debian: `sudo apt update && sudo apt install stress`
  - macOS: `brew install stress`
  - Windows: Use WSL2 with Ubuntu or a similar tool.
- A webhook URL from [webhook.site](https://webhook.site) for Alertmanager notifications.

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/monitoring-stack.git
   cd monitoring-stack
   Run the Setup Script:
   ```

```bash
chmod +x setup.sh
./setup.sh
```

The script checks for Docker and Docker Compose.
Prompts for a webhook.site URL (or skip to update alertmanager/alertmanager.yml manually).
Starts the Docker Compose stack.
Verifies services and opens UIs in your browser (Prometheus, Grafana, Alertmanager).

# Access Services:

Prometheus: http://localhost:9090
Check Status > Targets to confirm prometheus and node_exporter are UP.
Grafana: http://localhost:3000 (login: admin/securepassword123)
Import the Node Exporter Full dashboard (ID 1860) via Dashboards > Import.
Alertmanager: http://localhost:9093
Node Exporter: http://localhost:9100/metrics

# Testing the Setup

Visualize Metrics:
In Grafana, import the Node Exporter Full dashboard (ID 1860) from Grafana.com.
Verify CPU, memory, and disk metrics are displayed.
Trigger an Alert:
The setup.sh script runs stress --cpu 2 --timeout 360 (if stress is installed) to simulate high CPU usage.

Alternatively, run manually:

```bash
stress --cpu 2 --timeout 360
```

Wait 5 minutes for the HighCPUUsage alert to fire (threshold: >80% CPU for 5 minutes).
Verify Alerts:
Prometheus: Check http://localhost:9090/alerts for the HighCPUUsage alert.
Alertmanager: Check http://localhost:9093 for received alerts.
Webhook: Visit your webhook.site URL to confirm alert notifications (example payload below):

```json
{
  "alerts": [
    {
      "labels": { "alertname": "HighCPUUsage", "severity": "critical" },
      "annotations": {
        "summary": "High CPU usage detected on node_exporter:9100"
      }
    }
  ]
}
```

Cleanup
Stop and remove the Docker containers:

```bash

docker-compose down
```

## Security Considerations

Local Testing:
Prometheus is unsecured but only exposed on localhost:9090 within a Docker network.
Grafana uses a strong default password (admin/securepassword123).
Services are isolated in a monitoring Docker network.

## Production Recommendations:

Add a reverse proxy (e.g., Nginx) with basic authentication or TLS for Prometheus.
Use a secrets manager (e.g., Docker Secrets) for credentials.
Restrict ports (9090, 3000, 9093, 9100) with firewall rules.
Regularly update Docker images to patch vulnerabilities.

## Troubleshooting

Prometheus Targets Down:
Check logs: docker logs prometheus
Ensure node_exporter:9100 is reachable in the monitoring network.
Grafana Data Source Error:
Verify http://prometheus:9090 in grafana/provisioning/datasources/datasource.yml.
Alerts Not Firing:
Confirm CPU usage exceeds 80% (use top or Grafana dashboard).
Check Alertmanager logs: docker logs alertmanager
Webhook Issues:
Verify the webhook URL in alertmanager/alertmanager.yml.
Test with curl from the Alertmanager container:

```bash
docker exec alertmanager curl -X POST <your-webhook-url>
```

## Notes

The Node Exporter dashboard is imported manually for simplicity. To pre-provision, download the JSON from Grafana.com and place it in grafana/dashboards/system_metrics.json.
The setup.sh script automates deployment and testing, checking prerequisites and service status.
For scalability, consider Prometheus federation or Thanos (not implemented here).
Alertmanager uses a webhook receiver for testing; in production, configure email or Slack.

## References

Prometheus Documentation
Grafana Documentation
Node Exporter
Alertmanager
