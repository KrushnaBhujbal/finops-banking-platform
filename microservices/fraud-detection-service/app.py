"""
Generic dummy microservice for the FinOps Banking Platform lab.
Same code is reused for all 30+ services - behavior is driven entirely
by environment variables so each "service" looks distinct in logs,
metrics, and dashboards without writing 30 separate apps.
"""

import json
import logging
import os
import random
import sys
import time

from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

SERVICE_NAME = os.getenv("SERVICE_NAME", "generic-service")
SERVICE_DOMAIN = os.getenv("SERVICE_DOMAIN", "platform")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
# Controls how "flaky" this dummy service is, so some services can be made
# to demonstrate breached SLOs on purpose (e.g. payment-gateway-service).
ERROR_RATE = float(os.getenv("ERROR_RATE", "0.02"))
MIN_LATENCY_MS = int(os.getenv("MIN_LATENCY_MS", "20"))
MAX_LATENCY_MS = int(os.getenv("MAX_LATENCY_MS", "180"))

app = Flask(__name__)

# ---- Structured JSON logging (feeds the ELK / Filebeat sidecar) ----
class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "service": SERVICE_NAME,
            "domain": SERVICE_DOMAIN,
            "environment": ENVIRONMENT,
            "message": record.getMessage(),
        }
        if hasattr(record, "extra_fields"):
            payload.update(record.extra_fields)
        return json.dumps(payload)


logger = logging.getLogger(SERVICE_NAME)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logger.addHandler(handler)


def log_event(level, message, **extra_fields):
    record = logger.makeRecord(
        SERVICE_NAME, level, __file__, 0, message, None, None
    )
    record.extra_fields = extra_fields
    logger.handle(record)


# ---- Prometheus metrics (scraped via ServiceMonitor) ----
REQUEST_COUNT = Counter(
    "app_requests_total", "Total requests processed", ["service", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds", "Request latency in seconds", ["service", "endpoint"]
)
ERROR_COUNT = Counter(
    "app_errors_total", "Total errors raised", ["service", "endpoint"]
)


@app.route("/health")
def health():
    return jsonify(status="ok", service=SERVICE_NAME), 200


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/process", methods=["GET", "POST"])
def process():
    """Simulates a banking-style operation (e.g. transaction, KYC check)."""
    start = time.time()
    endpoint = "/process"

    simulated_latency = random.uniform(MIN_LATENCY_MS, MAX_LATENCY_MS) / 1000.0
    time.sleep(simulated_latency)

    is_error = random.random() < ERROR_RATE
    duration = time.time() - start
    REQUEST_LATENCY.labels(service=SERVICE_NAME, endpoint=endpoint).observe(duration)

    if is_error:
        REQUEST_COUNT.labels(service=SERVICE_NAME, endpoint=endpoint, status="500").inc()
        ERROR_COUNT.labels(service=SERVICE_NAME, endpoint=endpoint).inc()
        log_event(
            logging.ERROR,
            "request failed",
            endpoint=endpoint,
            duration_ms=round(duration * 1000, 2),
            trace_id=request.headers.get("X-Trace-Id", "dummy-trace"),
        )
        return jsonify(status="error", service=SERVICE_NAME), 500

    REQUEST_COUNT.labels(service=SERVICE_NAME, endpoint=endpoint, status="200").inc()
    log_event(
        logging.INFO,
        "request processed",
        endpoint=endpoint,
        duration_ms=round(duration * 1000, 2),
        trace_id=request.headers.get("X-Trace-Id", "dummy-trace"),
    )
    return jsonify(status="ok", service=SERVICE_NAME, latency_ms=round(duration * 1000, 2)), 200


if __name__ == "__main__":
    log_event(logging.INFO, f"{SERVICE_NAME} starting up", domain=SERVICE_DOMAIN, environment=ENVIRONMENT)
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
