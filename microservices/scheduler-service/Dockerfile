FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Overridden per-service at deploy time via Helm values / env vars
ENV SERVICE_NAME=generic-service
ENV SERVICE_DOMAIN=platform
ENV ENVIRONMENT=dev
ENV ERROR_RATE=0.02
ENV MIN_LATENCY_MS=20
ENV MAX_LATENCY_MS=180
ENV PORT=8080

EXPOSE 8080

CMD ["python", "app.py"]
