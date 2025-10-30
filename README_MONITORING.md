Monitoring and Logging for user-service

This document shows how to access metrics and logs for the `user-service`.

1) Structured logs
- `logback-spring.xml` is configured to produce JSON structured logs using Logstash encoder.

2) Metrics
- The application exposes Prometheus metrics at `/actuator/prometheus` when running with the `prod` profile.

3) Locally with Docker Compose
- Start the stack:
```
docker compose --env-file user-service/.env up --build
```
- Access logs via `docker logs -f user-service`
- Access Prometheus metrics at `http://localhost:8080/actuator/prometheus`

4) Prometheus scraping
- Configure your Prometheus to scrape `http://<host>:8080/actuator/prometheus`.

Notes
- Do not expose `/actuator/prometheus` publicly without network protection.
