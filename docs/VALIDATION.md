# Validation record

Validated locally on 2026-09-18. A command is not marked successful unless it was actually executed in this workspace.

| Check | Status | Notes |
| --- | --- | --- |
| `terraform fmt -check -recursive` | Pass | Exit code 0 after formatting |
| Workload `terraform init -backend=false` | Pass | AWS Provider 6.65.0 installed |
| Workload `terraform validate` | Pass | Valid with no warnings after correction |
| Bootstrap `terraform init -backend=false` | Pass with retry note | Provider initialized in an isolated data directory; a redundant local init later hit a transient Windows file lock |
| Bootstrap `terraform validate` | Pass | Configuration is valid |
| `terraform plan` | Not run | AWS CLI and an AWS identity are unavailable on this machine |
| Terraform mock plan tests | Pass | Bootstrap and enabled-service plans passed; 2 runs and 9 assertions |
| tflint | Pass | Recursive module scan completed with zero findings after correcting module constraints and an unused input |
| Trivy Terraform scan | Pass | Zero unsuppressed High/Critical findings; three documented design exceptions |
| Application tests | Pass | 3 pytest tests passed; one third-party deprecation warning |
| Docker build | Pass | Built `platform-portfolio:test`; base image resolved and was pinned to its verified digest |
| Hadolint | Pass | Dockerfile completed with zero findings |
| Container smoke test | Pass | Non-root container reached Docker `healthy` and returned `{"status":"ok"}` from `/health` |
| PostgreSQL integration | Pass | Disposable API and PostgreSQL containers returned `{"status":"ready"}` from `/ready` |
| Trivy image/secret scan | Pass | Zero High/Critical vulnerabilities and zero detected secrets after OS/application upgrades and runtime pip removal |
| GitHub Actions | Not run | Requires a pushed repository, OIDC role, state-bucket variable, and protected environments |
| AWS deploy / HTTP health check | Not run | Requires credentials, cost acceptance, initial ECR push, and deployment |

## Required public-release gate

1. Run the full CI workflow in a private repository first.
2. Review a real plan against an isolated AWS account.
3. Deploy, wait for ECS stability, and verify `/health` and `/ready`.
4. Execute at least one controlled incident game day and retain sanitized evidence.
5. Destroy the workload and confirm the state bucket remains protected.
