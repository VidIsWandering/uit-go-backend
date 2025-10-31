# Monitoring and Logging

This document shows how to access metrics and logs for all services.

## 1. User Service

### Structured logs
- `logback-spring.xml` is configured to produce JSON structured logs using Logstash encoder.

### Metrics
- The application exposes Prometheus metrics at `/actuator/prometheus` when running with the `prod` profile.

### Local Setup with Docker Compose
```bash
docker compose --env-file .env up --build
```
- Access logs via `docker logs -f user-service`
- Access Prometheus UI: `http://localhost:9090`
- Access Grafana: `http://localhost:3000` (default: admin/admin)
- Direct metrics endpoint: `http://localhost:8080/actuator/prometheus`

## 2. Configuration

### Prometheus
- Configuration file: `prometheus.yml`
- Metrics are scraped every 15s by default
- All services are auto-discovered

### Grafana
- Default dashboards in `dashboards/`
- Auto-provisioned on startup
- Pre-configured Prometheus datasource

## Security Notes
- Do not expose monitoring endpoints publicly
- Use network segmentation in production
- Change default Grafana password
- Use secure TLS in production