# Validation record

Validated locally on 2026-09-18 (this session). A command is marked successful only if it was actually executed in this workspace on this date.

| Check | Status | Notes |
| --- | --- | --- |
| `terraform fmt -check -recursive` | PASS | Exit code 0, run 2026-09-18 |
| Workload `terraform init -backend=false` | PASS | AWS Provider 6.65.0 installed, run 2026-09-18 |
| Workload `terraform validate` | PASS | Configuration valid, run 2026-09-18 |
| Bootstrap `terraform init -backend=false` | PASS | Run 2026-09-18 |
| Bootstrap `terraform validate` | PASS | Run 2026-09-18 |
| Terraform mock plan tests (`terraform test`) | PASS | `tests/offline.tftest.hcl`: 2 passed, 0 failed, run 2026-09-18 |
| `terraform plan` (real AWS) | BLOCKED | No AWS CLI / credentials on this machine; no resources created |
| tflint | NOT RUN | Not installed on this machine; CI workflow runs `tflint --recursive` |
| Trivy config/image scan | NOT RUN | Not installed on this machine; CI workflow runs Trivy config + image scans |
| Application tests (`pytest app`) | PASS | 3 passed, 1 third-party deprecation warning (starlette TestClient), run 2026-09-18 |
| Docker build | PASS | Built `platform-portfolio:verify` from `app/`, run 2026-09-18 |
| Container smoke test (`/health`) | PASS | Container reached Docker `healthy`; `curl /health` returned `{"status":"ok"}`, run 2026-09-18 |
| PostgreSQL integration (`/ready`) | PASS | Disposable `postgres:16-alpine` + API containers; `/ready` returned `{"status":"ready"}`, run 2026-09-18 |
| GitHub Actions execution | NOT RUN | Requires pushed repo, OIDC role, state-bucket variable, protected environments |
| AWS deploy / ALB / RDS verification | NOT RUN | Requires credentials, cost acceptance, ECR push, deployment |

## Tool availability on this machine (2026-09-18)

- Terraform v1.14.3: available.
- Docker (client 29.7.2, Desktop 4.90.0): available.
- Python 3.13.15 + project `.venv` with pytest 8.4.1: available.
- AWS CLI, tflint, Trivy, Hadolint: not installed — recorded as BLOCKED/NOT RUN, not as passes.

## Required public-release gate

1. Run the full CI workflow in a private repository first.
2. Review a real plan against an isolated AWS account.
3. Deploy, wait for ECS stability, and verify `/health` and `/ready`.
4. Execute at least one controlled incident game day and retain sanitized evidence.
5. Destroy the workload and confirm the state bucket remains protected.
