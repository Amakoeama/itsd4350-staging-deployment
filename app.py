
import os
import time

from flask import Flask, Response, g, jsonify, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

app = Flask(__name__)

# Read the environment configuration.
APP_ENV = os.getenv("APP_ENV", "development")
app.config["APP_ENV"] = APP_ENV

# --- Read application version ---
APP_VERSION = os.getenv("APP_VERSION", "1.0")
app.config["APP_VERSION"] = APP_VERSION


# Prometheus application monitoring metrics.
REQUEST_COUNT = Counter(
    "flask_http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_DURATION = Histogram(
    "flask_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
)

ERROR_COUNT = Counter(
    "flask_http_errors_total",
    "Total HTTP requests returning 4xx or 5xx responses",
    ["method", "endpoint", "status"],
)


@app.before_request
def start_request_timer():
    g.request_start_time = time.perf_counter()


@app.after_request
def record_request_metrics(response):
    if request.path == "/metrics":
        return response

    endpoint = request.url_rule.rule if request.url_rule else "unmatched"
    method = request.method
    status = str(response.status_code)

    duration = time.perf_counter() - g.request_start_time

    REQUEST_COUNT.labels(method, endpoint, status).inc()
    REQUEST_DURATION.labels(method, endpoint).observe(duration)

    if response.status_code >= 400:
        ERROR_COUNT.labels(method, endpoint, status).inc()

    return response


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.route("/")
def home():
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>ITSD-4350 Staging Deployment</title>
    </head>
    <body>
        <h1>ITSD-4350 Automated Deployment Pipeline</h1>
        <p>Mini Project 2.1: Continuous Delivery to Staging</p>
        <p>Environment: {APP_ENV}</p>
    <p>Application Version: {APP_VERSION}</p>
        <p>Status: Application Running Successfully</p>
    </body>
    </html>
    """


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "environment": app.config["APP_ENV"],
        "version": app.config["APP_VERSION"],
        "application": "ITSD-4350 Mini Project 2.1"
    }), 200


if __name__ == "__main__":
    app.run(debug=APP_ENV == "development")
