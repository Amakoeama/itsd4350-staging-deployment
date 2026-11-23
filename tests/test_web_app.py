from app import app


def test_homepage_status():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200


def test_homepage_content():
    client = app.test_client()
    response = client.get("/")
    assert b"ITSD-4350 Automated Deployment Pipeline" in response.data
    assert b"Application Running Successfully" in response.data
