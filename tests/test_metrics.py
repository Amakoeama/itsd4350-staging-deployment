from app import app


def test_metrics_endpoint():
    client = app.test_client()

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "text/plain" in response.content_type


def test_request_counter():
    client = app.test_client()

    client.get("/")
    response = client.get("/metrics")
    metrics = response.get_data(as_text=True)

    assert 'flask_http_requests_total{' in metrics
    assert 'endpoint="/"' in metrics


def test_response_time_metric():
    client = app.test_client()

    client.get("/health")
    response = client.get("/metrics")
    metrics = response.get_data(as_text=True)

    assert "flask_http_request_duration_seconds_count" in metrics


def test_error_counter():
    client = app.test_client()

    client.get("/nonexistent-page")
    response = client.get("/metrics")
    metrics = response.get_data(as_text=True)

    assert "flask_http_errors_total{" in metrics
    assert 'status="404"' in metrics
