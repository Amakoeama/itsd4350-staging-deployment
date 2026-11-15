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
echo "No deployment performed yet."

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
echo "Safety check complete. No deployment performed."

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
echo "Safety verification complete. No deployment performed."
