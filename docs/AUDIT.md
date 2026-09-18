# Repository audit

Initial static audit performed on 2026-09-18 before corrective changes. Severity reflects portfolio publication risk as well as runtime impact. Execution results are recorded separately in `VALIDATION.md`; static inspection is not execution proof.

## Critical

None identified by static inspection.

## High

| Finding | Why it matters | Disposition |
| --- | --- | --- |
| No real AWS plan or deployment evidence exists | Provider/API behaviour, endpoint availability, IAM, ECS startup, ALB registration, and RDS connectivity are not proven by `validate` or mock plans | Keep explicitly `BLOCKED`/`NOT RUN` until an authorised sandbox run |
| GitHub Actions execution is unverified | YAML inspection cannot prove OIDC trust, environment protection, state access, or hosted-runner behaviour | Keep workflow execution `NOT RUN`; require a private-repository run before publication claims |
| Release workflow does not wait for ECS stability or perform a smoke test | `terraform apply` can succeed before the new deployment is demonstrably healthy | Add stability and HTTP health checks; retain manual environment approval |

## Medium

| Finding | Why it matters | Disposition |
| --- | --- | --- |
| CI grants `id-token: write` to jobs that do not use AWS | Broader token-minting permission than required weakens least privilege | Move permissions to the plan job only |
| Deployment applies an unsaved, unreviewed plan with `-auto-approve` | The applied change is not the exact reviewed artifact | Generate and show a saved plan immediately before the protected apply |
| Public ALB is HTTP-only | Requests have no transport confidentiality or integrity | Accept only for a disposable demo; require ACM/HTTPS before non-demo use |
| RDS is Single-AZ and service has no autoscaling | Availability claims must remain bounded to the portfolio design | Preserve cost-conscious defaults and document production differences |
| Availability alarm is a short-window symptom alarm, not an SLO burn-rate implementation | It cannot represent a rolling 30-day objective or missing/low-traffic behaviour fully | Document limitation; do not claim complete SLO enforcement |
| Endpoint security group permits HTTPS from the whole VPC | It is broader than the current ECS-only consumer contract | Prefer an ECS security-group reference to make the trust boundary explicit |
| Required publication and interview reports are absent | Reviewers cannot quickly distinguish evidence, limitations, and explainability | Add `INTERVIEW_GUIDE.md` and `PUBLICATION_REPORT.md` after validation |
| README lacks a compact validation matrix and CI badge | The first screen does not clearly distinguish verified work from design | Add concise status evidence without inflating claims |

## Low

| Finding | Why it matters | Disposition |
| --- | --- | --- |
| Existing validation records prior successful local runs | Those records may be true historically but are not evidence for this review session | Replace with timestamped results from commands actually run now |
| Application tests cover only health/configuration failure paths | The small API is intentional, but behavioural confidence is narrow | Keep scope small; add only tests that protect meaningful contracts |
| Incident scenarios are designed but not AWS game-day executed | Reasoning is useful, but operational execution must not be implied | Label each scenario as designed/not executed |
| Several Terraform module inputs/outputs use compact one-line declarations | Valid but slightly harder to scan and document | No broad reformat solely for style |

## AWS runtime path review

The intended no-NAT startup path is structurally complete:

1. Fargate resolves private AWS service names because VPC DNS support/hostnames and interface-endpoint private DNS are enabled.
2. The ECS agent reaches ECR API and ECR DKR over TCP/443 through interface endpoints.
3. ECR image layers are downloaded from S3 through the S3 gateway endpoint attached to both private route tables.
4. The ECS agent retrieves the exact RDS-managed secret through the Secrets Manager interface endpoint using the execution role.
5. The `awslogs` driver reaches CloudWatch Logs through the Logs interface endpoint.
6. The application reaches RDS on TCP/5432 through reciprocal SG references.

Static caveat: actual endpoint provisioning, DNS answers, IAM evaluation, image pull, secret injection, log delivery, and database TLS remain unverified without an authorised AWS deployment.

## Areas reviewed

Terraform roots/modules and locks; state bootstrap; network routes, endpoints, and security groups; ECS/ALB/ECR/IAM; RDS and Secrets Manager integration; CloudWatch/SNS; application and Docker image; GitHub Actions and PR template; SLI/SLO, incidents, postmortem, architecture, migration, validation, final review, and ignore rules.
