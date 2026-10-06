"""Test suite for PatchPilot FastAPI application."""

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Verify root endpoint returns HTTP 200 and PatchPilot metadata."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "PatchPilot"
    assert data["status"] == "operational"
    assert "version" in data


def test_health_endpoint():
    """Verify health endpoint returns HTTP 200 and healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data == {"status": "healthy"}


def test_not_found_endpoint():
    """Verify non-existent endpoint returns HTTP 404."""
    response = client.get("/invalid-endpoint")
    assert response.status_code == 404


