#!/usr/bin/env bash

#--- Mini Project 2.3: Blue/Green Deployment Automation ---
#--- Purpose: Deploy the inactive production environment ---

set -euo pipefail

#--- Identify the project directory ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

#--- Locate the Docker Compose configuration ---
COMPOSE_FILE="$PROJECT_ROOT/infrastructure/blue-green/docker-compose.yml"

#--- Confirm the configuration exists ---
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "ERROR: Docker Compose configuration not found."
    exit 1
fi

echo "Blue/Green deployment configuration located."
echo "Compose file: $COMPOSE_FILE"

#--- Locate the active NGINX routing configuration ---
NGINX_CONFIG="$PROJECT_ROOT/infrastructure/blue-green/nginx/nginx.conf"

#--- Verify the NGINX configuration exists ---
if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo "ERROR: NGINX configuration not found."
    exit 1
fi

#--- Identify the active production environment ---
if grep -Eq '^[[:space:]]*server[[:space:]]+blue:8000;' "$NGINX_CONFIG"; then
    ACTIVE_ENV="blue"
    INACTIVE_ENV="green"

elif grep -Eq '^[[:space:]]*server[[:space:]]+green:8000;' "$NGINX_CONFIG"; then
    ACTIVE_ENV="green"
    INACTIVE_ENV="blue"

else
    echo "ERROR: Unable to identify the active production environment."
    exit 1
fi

#--- Display the deployment decision ---
echo "Active production environment: $ACTIVE_ENV"
echo "Inactive deployment target: $INACTIVE_ENV"

#--- Verify routing configuration inside NGINX ---
echo "Checking NGINX container configuration..."

RUNNING_NGINX_CONFIG="$(docker exec itsd4350-nginx nginx -T 2>/dev/null)"

if ! grep -Eq "^[[:space:]]*server[[:space:]]+$ACTIVE_ENV:8000;" \
    <<< "$RUNNING_NGINX_CONFIG"; then
    echo "ERROR: NGINX container configuration does not match."
    exit 1
fi

echo "NGINX configuration matches the expected active environment."

#--- Verify the live production environment ---
echo "Checking live production traffic..."

#--- Request the production health endpoint ---
HEALTH_RESPONSE="$(curl --fail --silent --show-error \
    --max-time 5 http://localhost:8080/health)"

#--- Extract the environment using Python ---
LIVE_ENV="$(printf '%s' "$HEALTH_RESPONSE" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
print(data.get("environment", "unknown"))
')"

#--- Confirm the live environment matches NGINX routing ---
EXPECTED_ENV="production-$ACTIVE_ENV"

if [[ "$LIVE_ENV" != "$EXPECTED_ENV" ]]; then
    echo "ERROR: Production routing mismatch!"
    echo "Expected: $EXPECTED_ENV"
    echo "Actual: $LIVE_ENV"
    exit 1
fi

#--- Confirm production is healthy ---
printf '%s' "$HEALTH_RESPONSE" | python3 -c '
import json
import sys

data = json.load(sys.stdin)

if data.get("status") != "healthy":
    print("ERROR: Production health check failed.")
    sys.exit(1)

print("Production health check passed.")
'

echo "Live production environment: $LIVE_ENV"
echo "Inactive deployment target: $INACTIVE_ENV"

#--- Deploy only the inactive environment ---
echo "Preparing deployment to: $INACTIVE_ENV"

#--- Build and recreate the inactive application container ---
docker compose -f "$COMPOSE_FILE" up \
    -d \
    --build \
    --no-deps \
    --force-recreate \
    "$INACTIVE_ENV"

echo "Inactive environment deployment command completed."

#--- Validate the inactive environment after deployment ---
echo "Validating deployment to: $INACTIVE_ENV"

#--- Expected environment identifier ---
EXPECTED_INACTIVE_ENV="production-$INACTIVE_ENV"

#--- Retry health checks while the application starts ---
HEALTH_CHECK_PASSED=false

for attempt in {1..10}; do
    echo "Health check attempt: $attempt/10"

    if docker exec "itsd4350-$INACTIVE_ENV" python -c '
import json
import sys
import urllib.request

expected_environment = sys.argv[1]

try:
    with urllib.request.urlopen(
        "http://localhost:8000/health", timeout=5
    ) as response:
        data = json.load(response)

    if (
        data.get("status") == "healthy"
        and data.get("environment") == expected_environment
    ):
        print("Health check passed:", data)
        sys.exit(0)

except Exception as error:
    print("Health check error:", error)

sys.exit(1)
' "$EXPECTED_INACTIVE_ENV"; then
        HEALTH_CHECK_PASSED=true
        break
    fi

    sleep 2
done

#--- Stop if the inactive deployment is unhealthy ---
if [[ "$HEALTH_CHECK_PASSED" != "true" ]]; then
    echo "ERROR: Inactive environment failed health validation."
    echo "Production traffic remains assigned to: $ACTIVE_ENV"
    exit 1
fi

echo "Inactive environment is healthy: $INACTIVE_ENV"
echo "Deployment validation completed."
echo "Production traffic has NOT been switched."
