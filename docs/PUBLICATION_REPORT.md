# Publication report

Date: 2026-09-18. Scope: local static review plus commands actually executed in this workspace on this date. Nothing below claims AWS execution that did not happen.

## Final verdict

**CONDITIONALLY READY** — publishable as a portfolio with the stated limitations, not as a deployed platform.

Reason: no Critical findings remain in the static review, and every locally executable check passes. The blocking gaps are environmental (no AWS credentials, no GitHub execution), not code defects. The README, validation record, and docs label those gaps BLOCKED/NOT RUN, so a reviewer is never misled. Public framing must stay "designed and locally validated; AWS deployment pending" until the release gate in `docs/VALIDATION.md` is completed.

## Score (10-point scale, strict)

| Area | Score | Basis |
| --- | --- | --- |
| First Impression | 8 | README answers stack/architecture/status in under 2 minutes; badges restrained |
| Terraform | 7 | fmt/init/validate/mock-tests pass; version pins and module boundaries clean; real plan unverified |
| AWS Architecture | 7 | No-NAT path structurally complete and traced; endpoint/DNS/SG reasoning explicit; runtime unproven |
| Container | 8 | Build, healthy status, `/health` 200, and `/ready` against disposable PostgreSQL all executed today |
| Security | 7 | Least-privilege roles, private subnets, managed secret, scans in CI; endpoint SG CIDR scope is a documented trade-off; scans not run locally |
| CI/CD | 6 | OIDC, saved-plan apply, stability wait, smoke test all reviewed in YAML; never executed on GitHub |
| Observability | 7 | User→service→infra alarm ordering with stated thresholds; burn-rate and deploy-event gaps admitted |
| SRE / Reliability | 7 | SLI/SLO/error-budget limits honestly bounded; incidents are evidence-driven but game-day unexecuted |
| Documentation | 8 | Concise, cross-linked, no inflated claims; interview guide added this session |
| Code Quality | 8 | Small, reviewable, no unexplained resources; no gratuitous abstraction |
| Interview Explainability | 9 | 29 grounded Q&A in `docs/INTERVIEW_GUIDE.md`; every answer points at a file or doc |
| Portfolio Value | 8 | Transferable reasoning (change safety, trust boundaries, failure analysis) visible without buzzword stuffing |

No category with unverified execution was given full marks.

## What was actually executed (2026-09-18, this machine)

- `terraform fmt -check -recursive`: PASS (exit 0).
- `terraform -chdir=infra init -backend=false`: PASS (provider 6.65.0).
- `terraform -chdir=infra validate`: PASS.
- `terraform -chdir=bootstrap init -backend=false` / `validate`: PASS.
- `terraform -chdir=infra test`: PASS (2 passed, 0 failed).
- `pytest app`: PASS (3 passed).
- `docker build -t platform-portfolio:verify app`: PASS.
- Container run: Docker `healthy`, `curl /health` → `{"status":"ok"}`: PASS.
- Disposable `postgres:16-alpine` + API: `curl /ready` → `{"status":"ready"}`: PASS.
- Tool availability check: Terraform/Docker/Python present; AWS CLI, tflint, Trivy, Hadolint absent.

## What remains unverified

- `terraform plan` against real AWS: BLOCKED (no CLI/credentials).
- `terraform apply` + ECS RUNNING + ALB HEALTHY + HTTP checks + RDS connectivity + log delivery: NOT RUN.
- GitHub Actions execution (CI + deploy): NOT RUN — YAML reviewed only.
- tflint / Trivy / Hadolint locally: NOT RUN — covered by CI definition, not by local evidence.
- Incident game days on AWS: designed, NOT RUN.
- Cost behavior: estimated in prose, never metered.

## Critical / High issues

- Critical: none in static review.
- High (all explicitly BLOCKED/NOT RUN, none misrepresented):
  1. No real AWS plan reviewed — closed only by a saved plan + checklist review in an isolated account.
  2. No deployment/HTTP/RDS evidence — closed only by stable service, healthy targets, `/health` + `/ready` 200.
  3. GitHub Actions never executed — closed only by green PR CI + approval-gated deploy run.
- Previously open High items closed in code this review cycle: `id-token: write` scoped to the plan job; deploy workflow now plans/saves, shows, applies the same artifact, waits for `services-stable`, and smoke-tests `/health`; root outputs `ecs_cluster_name`/`ecs_service_name` added for verification; README validation matrix + badges added.

## Evaluated and intentionally not changed

- Endpoint SG allows 443 from the VPC CIDR instead of referencing the ECS SG. Passing the root ECS SG into the network module would create a dependency cycle (root SGs need the module's `vpc_id`). The correct fix is relocating the endpoint SG beside its consumers — a refactor disproportionate to the gain in a single-workload VPC. Kept as a documented trade-off in `docs/AUDIT.md` and `docs/INTERVIEW_GUIDE.md` Q10.

## Changes made (this review cycle)

1. `docs/AUDIT.md`: created — severity-graded findings plus the no-NAT runtime-path trace.
2. `.github/workflows/ci.yml`: least-privilege `id-token` scoping to the plan job.
3. `.github/workflows/deploy.yml`: saved-plan apply, `services-stable` wait, `/health` smoke test.
4. `infra/outputs.tf`: verification outputs for cluster/service names.
5. `README.md`: badges, validation snapshot, NAT/liveness/bootstrap/approval trade-offs.
6. `docs/VALIDATION.md`: rewritten with timestamped 2026-09-18 results and tool-availability disclosure.
7. `docs/INTERVIEW_GUIDE.md`: created — 29 implementation-grounded Q&A.
8. `docs/PUBLICATION_REPORT.md`: this file.

## Strongest portfolio points

- Honest verification boundary: PASS / BLOCKED / NOT RUN never mixed.
- No-NAT startup path traced hop by hop, with cost caveat instead of a cheapness claim.
- Execution/task role separation proven by a dedicated incident scenario.
- Liveness vs readiness reasoning that prevents restart amplification.
- Change safety made visible: immutable SHA tags, saved-plan apply, approval gate, plan checklist.

## Weakest portfolio points

- Zero AWS runtime evidence — the single largest discount across scores.
- CI/CD is reviewed YAML, not green runs.
- SLO implementation is a symptom alarm, not burn-rate alerting; no deployment-failure event alarm.
- Single-AZ RDS default bounds every availability claim.
- Local scans depend on CI; no local tflint/Trivy evidence on this machine.

## Questions likely to be asked in interviews

Covered in depth in `docs/INTERVIEW_GUIDE.md`. The five most probable: NAT-less ECR pull path; execution vs task role; why ALB checks liveness not readiness; S3 `use_lockfile` vs DynamoDB; why apply is manual and plan-gated.

## Recommended next actions (in order)

1. Push to a **private** repo; run PR CI green; keep the log.
2. Real `terraform plan` in an isolated account; file the saved plan + completed `TERRAFORM_PLAN_REVIEW.md`.
3. Deploy → ECR push → stable service → `/health` + `/ready` 200 → destroy; record all in `VALIDATION.md`.
4. Execute one incident game day (Incident 3 is cheapest) with sanitized evidence.
5. Add deployment-failure event alerting and multi-window burn-rate alarms.
6. Then publish public and reference this report.

## Ready for public GitHub?

Conditionally yes — with the current "locally validated, AWS pending" framing intact. If any claim implies deployed/proven AWS behavior, the answer reverts to NOT READY until the release gate is executed.
