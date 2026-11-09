# Terraform Staging Deployment Guide

## Project Overview

This project demonstrates Infrastructure as Code for a Flask staging environment using Terraform, Docker, and GitHub Actions.

## Prerequisites

- Linux or WSL with Docker Engine
- Terraform 1.14.8
- Git
- Bash and curl
- Permission to access the Docker daemon

## Infrastructure Configuration

Terraform configuration files are located in:

infrastructure/terraform/staging/

The infrastructure includes a Docker network and a Flask application container. Variables control the project name, environment, Docker image, and application ports.

## Automated Provisioning

From the repository root, run:

    ./scripts/provision_staging.sh

The script builds the Docker image, initializes Terraform, validates the configuration, provisions the infrastructure, and checks application health.

Docker permissions must be configured before running the script. On the local WSL environment, the script was tested using sudo.

## Manual Provisioning

Build the application image:

    docker build -t itsd4350-staging-app:1.0 .

Initialize Terraform:

    terraform -chdir=infrastructure/terraform/staging init

Validate the configuration:

    terraform -chdir=infrastructure/terraform/staging validate

Provision infrastructure:

    terraform -chdir=infrastructure/terraform/staging apply

Verify the application:

    curl -i http://localhost:8000/health

Expected result: HTTP 200 OK with environment set to staging.

## Idempotence

Running Terraform plan after successful provisioning should report:

    No changes. Your infrastructure matches the configuration.

This demonstrates that the declared infrastructure matches the running environment.

## Destruction and Recreation

Destroy the environment:

    terraform -chdir=infrastructure/terraform/staging destroy

Recreate the environment:

    terraform -chdir=infrastructure/terraform/staging apply

Verify the recreated application using the health endpoint.

## GitHub Actions Integration

The workflow is defined in:

.github/workflows/terraform-staging.yml

It automatically provisions staging, checks idempotence, destroys the infrastructure, recreates it, and performs cleanup.

GitHub-hosted runners are temporary. This workflow verifies infrastructure reproducibility and does not provide permanent staging hosting.

## Evidence

- Amakoe_01_Staging_Deployment_and_Idempotence.png
- Amakoe_02_Terraform_Destroy.png
- Amakoe_03_Terraform_Recreation.png
- Amakoe_04_Automated_Provisioning.png
- Amakoe_05_GitHub_Actions_Success.png

Evidence screenshots are stored in docs/screenshots/.

## Architecture

See STAGING_ARCHITECTURE.md for the infrastructure diagram, configuration, lifecycle, and design decisions.

## Cost Considerations

Local Docker provisioning does not require a paid cloud server. GitHub Actions executes the infrastructure lifecycle on temporary hosted runners, subject to GitHub's applicable usage limits.
