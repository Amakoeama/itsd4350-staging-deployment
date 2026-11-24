# Mini Project 2.4 — Deployment Validation Report

Date: November 24, 2026
Project: ITSD-4350 — Monitoring, Validation & Release Governance

## Scope
Validate the existing Flask Blue/Green Docker deployment, monitoring
instrumentation, Grafana dashboard, and alert notification behavior.

## Automated Code Validation
- Python environment: project `.venv`
- Command: `python -m pytest -q`
- Result: 9 tests passed in 1.17 seconds.
- Command: `python -m flake8 app.py src tests`
- Result: passed with no reported errors.

## Monitoring Configuration
Prometheus scrapes the Blue and Green Flask application instances.
Application metrics include:
- HTTP request counts by method, endpoint, and status.
- HTTP error counts.
- HTTP request duration histogram.
- Application target availability through Prometheus `up`.

Grafana dashboard panels:
1. Blue/Green target health.
2. HTTP request rate by environment.
3. HTTP error rate by environment.
4. P95 HTTP request latency by environment.

Configuration files:
- `infrastructure/monitoring/prometheus/prometheus.yml`
- `infrastructure/monitoring/grafana/dashboards/Amakoe_MP2.4_Grafana_BlueGreen_Dashboard.json`
- `infrastructure/blue-green/docker-compose.monitoring.yml`

## Alert Configuration
Application Down:
- Metric: `up{job="flask-blue-green"}`
- Trigger: value below 1.
- Evaluation interval: 30 seconds.
- Pending period: 2 minutes.

HTTP 5xx Error Rate:
- Metric: per-environment rate of HTTP 5xx responses.
- Trigger: above 0.1 errors per second.
- Evaluation interval: 30 seconds.
- Pending period: 2 minutes.

Both rules were saved in Grafana. The HTTP 5xx rule was observed
in Normal state; a real 5xx incident was not simulated.

## Notification Routing
A Grafana notification policy routes project-specific critical alerts
to the configured email contact point.

A test notification was received, and a real application-down alert
was delivered by email during the controlled outage.

SMTP credentials are supplied through environment variables and must
not be included in the repository or submission ZIP.

## Controlled Green Outage Test
Action: stopped the Green application container.

Observed:
- Prometheus reported Green unavailable.
- The Green Application Down alert progressed to Firing.
- Blue remained Normal.
- A real outage email notification was received.

Recovery action: restarted the Green container.

Recorded Grafana alert history:
- Pending: 14:27:20
- Alerting: 14:29:20
- Recovering: 14:35:20
- Normal: 14:36:20

A recovery email was received, and the application returned to Normal.

These times document observed alert transitions; they do not establish
a production uptime service-level objective.

## Final Assessment
- Automated application tests: PASS.
- Flake8 quality check: PASS.
- Prometheus target monitoring: VERIFIED.
- Grafana dashboard: CONFIGURED AND OBSERVED.
- Application-down alert: REAL OUTAGE TEST PASSED.
- Email notification and recovery: VERIFIED.
- HTTP 5xx alert: CONFIGURED; INCIDENT TEST NOT PERFORMED.
- Mandatory independent release approval: NOT ENFORCED.

## Limitations
This was a local demonstration, not a production deployment.
The existing GitHub Actions Render staging workflow is distinct from
the local Blue/Green Docker environment.

No long-term uptime percentage, availability SLA, or sustained-load
performance claim is made from these observations.
