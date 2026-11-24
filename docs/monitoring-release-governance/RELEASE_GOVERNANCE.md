# Mini Project 2.4 — Release Governance

## Purpose
Establish a repeatable process for reviewing, validating, approving,
deploying, monitoring, and, when necessary, rolling back releases.

## Deployment Environments
- CI/CD workflow: GitHub Actions.
- Existing hosted staging workflow: Render.
- Blue/Green demonstration environment: local Docker Compose and Nginx.
- Monitoring: Prometheus and Grafana.

The GitHub Actions Render deployment is separate from the local Docker
Blue/Green demonstration. The current workflow does not automatically
deploy changes to the local Docker environment.

## Release Roles
- Developer: prepares changes, tests, and deployment evidence.
- Release approver: reviews the release checklist and authorizes deployment.
- Operator: performs deployment, validates health, and initiates rollback.

For this individual academic project, these responsibilities may be
performed by the same student. Independent approval is not claimed.

## Release Approval Checklist
A release is ready for approval only when:

- [ ] The intended branch, commit, and changes are identified.
- [ ] Automated tests pass.
- [ ] Flake8 reports no errors.
- [ ] Relevant GitHub Actions checks pass.
- [ ] Deployment configuration and application health are reviewed.
- [ ] Prometheus targets and Grafana monitoring are healthy.
- [ ] Alert routing and notification configuration are reviewed.
- [ ] The rollback procedure is available.
- [ ] The release decision and supporting evidence are recorded.

## Release Decision
Record the following before a production-like release:

- Release identifier / commit:
- Date and time:
- Reviewer / approver:
- CI result:
- Staging validation result:
- Monitoring status:
- Decision: APPROVED / REJECTED / DEFERRED
- Reason and evidence:

## Existing GitHub Actions Controls
The existing CI workflow defines a build-and-test dependency for its
staging deployment job and references the GitHub environment `staging`.

The deployment job currently targets the historical
`feature/staging-deployment` branch and uses a Render deployment hook.
This is not a deployment path for the local Blue/Green Docker environment.

GitHub's Required reviewers setting was inspected but not configured.
Therefore, mandatory reviewer approval is NOT currently enforced.
This checklist provides a documented manual release decision process.

## Deployment Validation
1. Verify the selected application version and active environment.
2. Run automated tests and static analysis.
3. Confirm application health endpoints respond successfully.
4. Confirm Prometheus can scrape both Blue and Green targets.
5. Review Grafana health, request-rate, error-rate, and latency panels.
6. Review alert status and any active incidents.
7. Record the decision and deployment evidence.

## Rollback Criteria
Consider rollback when:
- The newly activated application fails its health check.
- Critical application-down alerts fire.
- HTTP 5xx errors exceed the defined alert threshold.
- Application behavior or latency is unacceptable.

## Rollback Procedure
For the local Blue/Green environment:
1. Identify the previously healthy deployment color.
2. Use the existing Blue/Green switching procedure to restore traffic
   to that healthy environment.
3. Verify the Nginx endpoint and application health.
4. Confirm Prometheus and Grafana show recovery.
5. Record the incident, rollback decision, and evidence.

Do not assume that switching traffic has succeeded without validation.

## Audit Evidence
Preserve CI results, test output, deployment screenshots, monitoring
screenshots, alert notifications, and the recorded release decision.

## Current Governance Limitation
The release checklist documents approval criteria, but a mandatory
independent approval gate has not been demonstrated or enforced.
