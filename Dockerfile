# Stage 1: Build dependencies
FROM python:3.13-alpine AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Minimal hardened runtime image
FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    PATH="/install/bin:/usr/local/bin:${PATH}" \
    PYTHONPATH="/install/lib/python3.13/site-packages"

WORKDIR /app

# Create unprivileged system group and user
RUN addgroup -S -g 10001 appgroup && \
    adduser -S -u 10001 -G appgroup appuser

# Remove runtime package managers and vendored files to minimize attack surface
RUN rm -rf /usr/local/lib/python3.13/site-packages/pip*

# Copy runtime packages from builder stage
COPY --from=builder /install /install

# Copy application code
COPY app/ app/

# Secure file permissions
RUN chown -R appuser:appgroup /app /install

# Switch to unprivileged user
USER appuser

# Expose microservice port
EXPOSE 8000

# Start FastAPI application with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
