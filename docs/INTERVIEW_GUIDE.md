# Interview guide

Questions likely in an interview about this repository, with the implementation-grounded points behind each answer. This is a portfolio learning environment, not a production system operated for an employer.

## Architecture and compute

### 1. Why ECS Fargate instead of EKS?

The workload is one small API with no need for Kubernetes scheduling, custom operators, or multi-service orchestration. Fargate removes node management and keeps the Terraform surface small enough to review line by line. EKS would add control-plane cost and operational burden with no problem in this repo that requires it. Production with many services or a need for Kubernetes-native tooling would be the reason to revisit.

### 2. Why Fargate instead of EC2 launch type?

No servers to patch or scale, per-task security groups in `awsvpc` mode, and pay-per-task pricing fit a disposable demo. Points to `network_configuration` in `infra/modules/service/main.tf` (`assign_public_ip = false`, private subnets).

### 3. Why no NAT gateway?

The only outbound paths the tasks need are AWS APIs (ECR, Logs, Secrets Manager, S3 for image layers), all reachable through VPC endpoints. No NAT means no route for arbitrary internet egress, which makes dependencies explicit. Trade-off stated in `docs/ARCHITECTURE.md`: four interface endpoints have hourly cost and can exceed a single NAT gateway, so this is a demonstration, not a cost claim.

### 4. How does ECS pull from ECR without NAT?

`ecr.api` + `ecr.dkr` interface endpoints (private DNS on) carry API and token/layer-metadata traffic; the `s3` gateway endpoint attached to both private route tables carries layer downloads. VPC DNS support/hostnames are enabled. Verifiable in `infra/modules/network/main.tf`.

### 5. Gateway Endpoint vs Interface Endpoint?

S3 uses a Gateway endpoint (route-table entry, no hourly charge, S3/DynamoDB only). ECR/Logs/Secrets Manager use Interface endpoints (ENIs with private IPs in the private subnets, hourly + data charges, security-group controlled). That is why S3 appears as `route_table_ids` and the rest as `subnet_ids` + `security_group_ids` in the network module.

### 6. What breaks first if an endpoint is missing?

ECR endpoints missing → tasks never pull (`CannotPullContainerError`). Secrets Manager missing → `ResourceInitializationError` before the container starts (no app logs — see Incident 3). Logs missing → tasks may run but emit nothing. S3 gateway missing → pull fails at layer download even with ECR endpoints present.

## Roles, secrets, network

### 7. Execution role vs task role?

The ECS agent uses the **execution** role (pull image, fetch `DB_SECRET_JSON`, write logs). Application code uses the **task** role (here intentionally zero AWS permissions). Proof: `secrets` + `execution_role_arn` in the task definition; the secret policy attaches to `aws_iam_role.execution`. Incident 3 exists precisely because putting the permission on the wrong role fails.

### 8. How is the DB password managed?

RDS `manage_master_user_password = true` (check `infra/modules/database/main.tf`) makes RDS own the secret in Secrets Manager. Terraform never stores a password; the task definition references the secret ARN and the execution role allows `GetSecretValue` on that exact ARN only.

### 9. Why is RDS private?

No public ingress path exists: RDS sits in isolated DB subnets and its SG allows 5432 only from the ECS SG (`database_from_ecs`). Diagnostics use an approved task in the same SG rather than opening RDS publicly (Incident 2 investigation step 5).

### 10. Why does the endpoint SG allow 443 from the whole VPC CIDR?

Current rule in the network module allows HTTPS from `var.vpc_cidr`. Tightening it to reference the ECS SG would require the network module to consume a root-level SG that itself needs the network's `vpc_id` — a dependency cycle unless the endpoint SG moves out of the module. With a single workload in this VPC the CIDR scope is an accepted, documented trade-off; a team layout would place the endpoint SG alongside consumer SGs and use SG references.

## Health, load balancing, deployment

### 11. ALB health check vs container health check?

ALB checks `/health` every 30s (matcher 200, thresholds 2/3) and routes only to passing targets. The container `healthCheck` runs the same endpoint inside Docker so a hung process restarts locally. Both test liveness only — never the database.

### 12. Why doesn't the ALB check `/ready`?

If RDS stalls, every task would simultaneously go unhealthy, the ALB would drain all capacity, and ECS would churn tasks — amplifying a dependency incident into a full outage. Liveness keeps serving what it can while `/ready` degradation is detected separately (Incident 2 design).

### 13. Why does the first apply create the service with desired count 0?

`enable_service=false` → `desired_count = 0` builds ECR and the platform without starting tasks against an image tag that does not exist yet. Push the SHA-tagged image, then apply with `enable_service=true`. Prevents a guaranteed-failing first deployment.

### 14. Why immutable image tags by Git SHA?

`image_tag_mutability = "IMMUTABLE"` plus `${GITHUB_SHA}` tagging means a deployed tag always identifies one build; rollback is selecting a previous SHA, not guessing what `latest` pointed to. ECR lifecycle keeps the last 20 images.

### 15. What does the deployment circuit breaker do?

`enable = true, rollback = true` on the ECS service makes a failing rollout (e.g., Incident 3's secret regression) automatically roll back to the last healthy task set instead of sitting at 0 healthy.

## Terraform

### 16. Why remote state in S3?

State holds infrastructure metadata and sensitive values, so it stays out of Git in a separately bootstrapped bucket (versioned, encrypted, TLS-only, public access blocked). The bootstrap stack uses local state and never depends on the bucket it creates.

### 17. What is `use_lockfile=true` and why not DynamoDB?

S3-native locking (`.tflock` file) serializes writers without a separate table. DynamoDB locking is deprecated in current Terraform; HashiCorp's S3 backend docs recommend versioning + locking. Team follow-ups: IAM-scoped state paths per environment, never casual `force-unlock`.

### 18. How are module boundaries decided?

`network` (VPC/subnets/routes/endpoints), `service` (ECR/ECS/ALB/IAM), `database` (RDS/secret), `monitoring` (alarms/SNS) — each maps to one failure domain an on-call reasons about. SGs spanning modules live at the root to avoid cycles (see Q10).

### 19. How do you judge a plan's Replacement?

Checklist in `docs/TERRAFORM_PLAN_REVIEW.md`: replacements of the ECS service, ALB, subnets, or RDS are the high-risk ones (RDS replacement can mean data loss). Every replacement must map to an intended change; unrelated diffs reject the plan.

### 20. Which Terraform changes can destroy the database?

Engine version/storage changes that force replacement, subnet-group or identifier changes, or removing deletion protection. Guarded by `deletion_protection` variable, `skip_final_snapshot=false` default expectations, and the plan checklist's database row.

## CI/CD

### 21. How does GitHub Actions authenticate to AWS?

OIDC via `aws-actions/configure-aws-credentials` assuming `secrets.AWS_ROLE_ARN` — no static keys. `id-token: write` is scoped to the plan job (least privilege fix recorded in `docs/AUDIT.md`).

### 22. Why isn't apply automatic?

CI produces a plan artifact; deployment is a manually dispatched, `production`-environment-gated job that shows the saved plan, applies exactly it, waits for `services-stable`, and curls `/health`. A human approves every mutation; a stale plan is never applied.

### 23. Why is `terraform plan` skipped on fork PRs?

Forks must not receive AWS credentials, so the OIDC plan job runs only for same-repository PRs. Forks still get pytest, Docker build, fmt/validate, mock tests, tflint, and Trivy.

## Observability and SLO

### 24. How is the 99.9% availability SLI actually computed?

`non-5xx / total` from ALB target responses over 30 days; error budget 0.1% ≈ 43 min/month of full outage. It is a learning target: Single-AZ RDS cannot credibly promise it, and the current alarm is a short-window symptom alarm, not multi-window burn-rate alerting — both limits are stated in `docs/SLI_SLO.md`.

### 25. What does "p95 < 500ms" mean, and why 500ms?

95% of ALB `TargetResponseTime` samples in the window complete under 500ms. For this tiny API 500ms is a deliberately loose starting hypothesis (absorbs cold starts, cheap DB) that still catches dependency stalls. Production would derive it from user journeys and baselines.

### 26. What can't ALB 5xx tell you about user experience?

It misses client-side failures, low-traffic statistical noise, single-AZ partial degradation masked by averages, and missing telemetry (no data ≠ healthy). Production adds log/event-based SLIs, burn-rate alerts, and canaries — listed as follow-ups in the postmortem and README.

## Operations

### 27. ECS can't reach RDS — what do you check first?

Classify the error (timeout vs refused vs auth vs TLS), then: RDS status/events, task env host/port vs endpoint, both SG directions on 5432, subnet placement, then an in-SG diagnostic task for DNS/TCP. Full sequence in Incident 2.

### 28. Targets unhealthy after a deploy — what do you check first?

Target health reason codes (not the app), ECS desired/running/pending + stopped reasons, log group startup lines, port/path/matcher contract vs container port, then the plan diff for SG/target-group changes. Incident 1's modeled cause is a listen-port change without updating the contract.

### 29. What would you change first for production?

TLS via ACM + HTTPS redirect, Multi-AZ RDS with tested restore, autoscaling from measured baselines, burn-rate SLO alerts + deployment-failure events, image signing/SBOM, rotation-tested secrets, and customer-managed keys where policy demands. All listed in README's production considerations.
