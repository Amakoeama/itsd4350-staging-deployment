#!/usr/bin/env bash
set -euo pipefail

#--- Project configuration ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infrastructure/terraform/staging"
IMAGE_NAME="itsd4350-staging-app:1.0"
HEALTH_URL="http://localhost:8000/health"

#--- Build the staging application image ---
echo "Building staging Docker image..."
docker build -t "$IMAGE_NAME" "$PROJECT_ROOT"

#--- Initialize and validate Terraform ---
echo "Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init -input=false

echo "Validating Terraform configuration..."
terraform -chdir="$TERRAFORM_DIR" validate

#--- Provision staging infrastructure ---
echo "Provisioning staging environment..."
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve -input=false

#--- Verify application health ---
echo "Checking staging application health..."
for attempt in {1..15}; do
    if curl --fail --silent --show-error "$HEALTH_URL"; then
        echo
        echo "Staging deployment successful!"
        exit 0
    fi
    sleep 2
done

echo "ERROR: Staging application did not become healthy."
exit 1
