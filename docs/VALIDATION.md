# Validation record

Local checks validated 2026-09-18. AWS deployment validated 2026-09-18 (ap-northeast-1, SSO `portfolio` profile) and the temporary environment was destroyed the same day. A check is marked successful only if it was actually executed. Account IDs, ARNs, and credentials are intentionally omitted.

| Validation | Result |
| --- | --- |
| Terraform real AWS plan | PASS — 2026-09-18. Bootstrap: 5 add / 0 change / 0 destroy. Infra: 60 add / 0 change / 0 destroy, no update/destroy of existing resources; no NAT gateway, no EIP in plan |
| Terraform apply (bootstrap) | PASS — 5 added (S3 bucket, versioning Enabled, AES256, full public-access block, TLS-only policy verified via API) |
| Terraform apply (infra) | PASS — 60 added, 0 changed, 0 destroyed |
| ECR push | PASS — image built from `app/` and pushed with Git SHA tag (immutable tag, digest returned) |
| ECS Task RUNNING | PASS — `services-stable` wait succeeded; running 2 / desired 2 |
| ALB Target Health | HEALTHY — 2/2 targets healthy across both AZ subnets |
| /health | HTTP 200 — `{"status":"ok"}` via public ALB |
| /ready | HTTP 200 — `{"status":"ready"}` via public ALB (proves real RDS session, not a stub) |
| RDS connectivity | PASS — instance `available`, `db.t4g.micro`, Single-AZ, `PubliclyAccessible=false` |
| CloudWatch Logs | PASS — log streams present; uvicorn startup and ALB health-check lines visible via `logs tail` |
| CloudWatch alarms | PASS — all 7 alarms present, state OK (no forced firing) |
| Security assumptions | PASS — tasks have private IPs only (no public IP); RDS not public; execution role = managed policy + exact-secret read policy; task role = zero policies; 5 VPC endpoints present; 0 NAT gateways |
| Terraform destroy | PASS — 60 destroyed, cleanup verified via API (RDS/ALB/VPC/ECR/log-group/bucket all gone) |
| Cleanup verification | PASS — see "Destroy" section |

## Local / CI record (2026-09-18, unchanged)

| Check | Status | Notes |
| --- | --- | --- |
| `terraform fmt -check -recursive` | PASS | Exit code 0 |
| `terraform init -backend=false` + `validate` (infra, bootstrap) | PASS | AWS Provider 6.65.0 |
| Terraform mock plan tests | PASS | 2 passed, 0 failed |
| tflint / Trivy | PASS on CI | GitHub Actions run 35333147317 (not installed locally) |
| `pytest app` | PASS | 3 passed |
| Docker build + `/health` + `/ready` vs disposable PostgreSQL | PASS | Local containers |
| GitHub Actions non-AWS jobs | PASS | Run 35333147317 green |
| GitHub Actions AWS jobs | NOT RUN | No OIDC role/bucket; out of scope for this validation |

## AWS deployment notes (first real run)

- The no-NAT startup path worked as designed on the first attempt: ECR pull, Secrets Manager injection, and CloudWatch Logs delivery all succeeded through VPC endpoints with zero task failures (`services-stable` passed without intervention). No code or Terraform changes were required for the deploy itself.
- Deploy flow followed the README exactly: infra apply with `enable_service=false` (desired 0) → ECR push of SHA tag → plan/apply with `image_tag=<SHA>` + `enable_service=true` (task definition replaced, service updated in place, desired 2).
- No issues discovered during deploy; troubleshooting section was not needed.

## Game day (2026-09-18, single safe scenario)

Scenario: abrupt loss of 1 of 2 ECS tasks (`stop-task`, reason `portfolio-game-day-task-loss`).

- Symptom: 1 task stopped; service desired count stayed 2.
- Detection: ECS service state showed the gap; CloudWatch unhealthy-host alarm path exists (not forced to fire).
- Evidence: `/health` via ALB returned HTTP 200 during and after the event (remaining AZ capacity served traffic).
- Investigation: `describe-services` showed running count recovering; target group showed one `healthy` + one `initial` (replacement registering).
- Root cause (injected): manual task stop, simulating AZ/instance-level task loss.
- Recovery: automatic — ECS scheduler launched a replacement; running count returned to 2/2 within ~60s with no manual intervention and no Terraform change.
- State after: normal (2/2 healthy trend, /health 200).

## Destroy (2026-09-18, same day as deploy)

- `terraform plan -destroy`: 60 targets, exactly matching the 60 created resources. No unrelated resources.
- `terraform destroy` (infra): PASS — 0 added, 0 changed, 60 destroyed.
- State bucket: bootstrap has `prevent_destroy`, so `terraform destroy` was intentionally not used. Instead: verified contents were only our tfstate/tflock versions (16 versions + 6 markers, single key prefix), deleted all versions/markers via CLI, then deleted the bucket. `HeadBucket` returns 404.
- Cleanup verification: PASS — RDS `DBInstanceNotFound`, ALB `LoadBalancerNotFound`, ECS service INACTIVE (0/0), cluster INACTIVE, VPC `InvalidVpcID.NotFound`, ECR `RepositoryNotFoundException`, log group list empty, state bucket 404. No NAT gateway was ever created.

| Validation | Result |
| --- | --- |
| Terraform destroy | PASS |
| Cleanup verification | PASS |

## Required public-release gate

1. ~~Run the full CI workflow in a private repository first.~~ Done for non-AWS jobs (run 35333147317).
2. ~~Review a real plan against an isolated AWS account.~~ Done 2026-09-18 (60 add, reviewed by resource type).
3. ~~Deploy, wait for ECS stability, and verify `/health` and `/ready`.~~ Done 2026-09-18.
4. ~~Controlled incident game day~~ Done 2026-09-18 (task-loss scenario, automatic recovery, see "Game day" above).
5. ~~Destroy the workload and confirm cleanup~~ Done 2026-09-18 (60 destroyed, bucket removed, API-verified).
