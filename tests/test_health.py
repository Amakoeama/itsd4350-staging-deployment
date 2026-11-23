
import os
import subprocess
import sys

from app import app


def test_health_endpoint():
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json["status"] == "healthy"
    assert response.json["application"] == "ITSD-4350 Mini Project 2.1"


def test_staging_environment():
    env = os.environ.copy()
    env["APP_ENV"] = "staging"

    result = subprocess.run(
        [
            sys.executable,
            "-c",
            "from app import app; "
            "assert app.test_client().get('/health').json"
            "['environment'] == 'staging'",
        ],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr
