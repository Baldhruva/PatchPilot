"""PatchPilot FastAPI Application.

A lightweight, secure microservice designed for automated DevSecOps validation.
"""

from fastapi import FastAPI

app = FastAPI(
    title="PatchPilot",
    description="Automated DevSecOps Pipeline and Security Gate Platform",
    version="1.0.0",
)


@app.get("/")
def get_root():
    """Root endpoint identifying PatchPilot."""
    return {
        "name": "PatchPilot",
        "version": "1.0.0",
        "description": "Automated DevSecOps Pipeline & Continuous Security Platform",
        "status": "operational",
    }


@app.get("/health")
def get_health():
    """Health check endpoint for Kubernetes probes and monitoring."""
    return {
        "status": "healthy"
    }


