# Mini Project 2.1 — Automated Staging Deployment

## Project Overview
This project extends the existing Flask CI pipeline into an automated staging deployment workflow using GitHub Actions and Render.

Repository: https://github.com/Amakoeama/itsd4350-staging-deployment

Staging URL: https://itsd4350-staging-deployment.onrender.com

Health Check: https://itsd4350-staging-deployment.onrender.com/health

## Existing Build Process
The existing GitHub Actions workflow installs Python dependencies, checks Python syntax, runs flake8, and executes automated tests with pytest.

The workflow was extended to package the Flask application into staging-app.tar.gz and upload it as a GitHub Actions artifact.

## CD Platform Selection
GitHub Actions was selected for continuous deployment because it integrates directly with the existing CI workflow, supports job dependencies, and provides secure repository secrets.

Render was selected as the staging hosting platform because it supports Python Flask applications, Git-based deployments, environment variables, health checks, and deployment logs.

## Automated Deployment Workflow
1. A push to feature/staging-deployment starts GitHub Actions.
2. The build-and-test job installs dependencies and runs quality checks and tests.
3. The application is packaged and uploaded as a deployment artifact.
4. The deploy-staging job downloads and verifies the artifact.
5. GitHub Actions uses a protected repository secret to trigger the Render deploy hook.
6. Render builds and starts the Flask application from the configured Git branch.
7. GitHub Actions performs a staging health-check smoke test.

Note: The downloaded artifact is verified by GitHub Actions, but Render deploys the Git branch source rather than the artifact archive itself.

## Development and Staging Separation
Development uses APP_ENV=development by default.

The Render staging environment uses APP_ENV=staging.

Staging runs the Flask application with Gunicorn instead of Flask's development server.

The Render deploy hook is stored in GitHub Actions as the repository secret RENDER_DEPLOY_HOOK_URL. The secret value is not committed to the repository.

Render automatic deployments are disabled so deployment is triggered through the GitHub Actions CD workflow.

## Validation and Monitoring
Validation includes:
- Python syntax checks
- flake8 code quality checks
- pytest automated tests
- Deployment artifact verification
- Automated staging health-check smoke test
- GitHub Actions execution logs
- Render deployment and application logs

The /health endpoint reports application health and the active environment.

## Deployment Evidence
The submission includes screenshots of successful GitHub Actions jobs, deployment logs, Render's live service, and the staging health-check response.

## Limitations
Render rebuilds from the configured Git branch rather than directly deploying the downloaded GitHub Actions artifact.

The automated smoke test confirms that the staging endpoint is healthy, but does not independently prove that the newly triggered deployment finished. Render's deployment status and commit should be checked separately.

## Rollback
If a deployment fails, review GitHub Actions and Render logs. Restore a known-good Git revision and trigger a new Render deployment, or use Render's available rollback/redeploy controls.
