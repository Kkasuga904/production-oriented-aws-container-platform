# Publication report

Date: 2026-09-18. Updated after GitHub push + CI execution (see "GitHub phase" below). Scope: local commands actually executed in this workspace plus GitHub Actions runs actually observed. Nothing below claims AWS execution that did not happen.

## Final verdict

**READY** — real AWS deployment validated 2026-09-18 and the temporary environment destroyed the same day.

Reason: no Critical findings; local checks pass; non-AWS CI green; real plan reviewed (60 add, 0 change, 0 destroy); apply succeeded first try with no code changes; ECR/ECR-push/ECS/ALB/RDS/CloudWatch/security all verified against live AWS; game-day recovery observed; destroy + API-level cleanup verification complete. No claims exceed executed evidence. The only remaining NOT RUN items are the GitHub AWS-gated jobs (PR plan, dispatched deploy), which require standing credentials and are out of scope for a disposable validation.

## AWS validation phase (2026-09-18, ap-northeast-1, SSO profile)

Deployed once, verified end-to-end, destroyed same day. No standing environment remains.

## Git status

- Pre-deploy tree clean; post-validation changes are documentation only (no Terraform/app code changes were needed — deploy worked first try).
- Secret scan repeated before push: no credentials, account IDs, or state in tracked files.

## Commit

- `docs: record AWS deployment validation` (this report, VALIDATION.md, README note).

## Push

- `main` pushed without force after cleanup verification.

## GitHub Actions execution

- Unchanged from prior phase: non-AWS jobs green; AWS-gated jobs NOT RUN (no standing OIDC credentials by design for a disposable validation).

## Local validation

- Unchanged: all PASS as previously recorded.

## CI validation

- Unchanged: non-AWS jobs PASS on run 35333147317+.

## AWS validation

- PASS across the board: real plan (60 add reviewed), bootstrap apply (5, verified), infra apply (60), ECR push (SHA tag), ECS 2/2 RUNNING via `services-stable`, targets 2/2 healthy, `/health` 200, `/ready` 200 (real RDS), RDS available/private, logs + 7 alarms OK, security assumptions API-verified, task-loss game day with automatic recovery, destroy (60) + cleanup API-verified + state bucket removed.

## Remaining blockers

- None for publication. Future work (not blockers): credentialed PR-plan run, dispatched deploy-workflow run, burn-rate alarms, deployment-failure event alert.

## Publication verdict

**READY.**

## Prior phase history (CI execution, kept for audit trail)

Prior commits: `9552e5b` (local validation + docs), `169d72f` + `a907d93` (trivy-action fixes — bad tag, stale Trivy default caught only by execution), `d145a67` (CI evidence + badge). CI runs 35332841565/35332899546 (failures, fixed) → 35333147317/35333333871 (green, non-AWS jobs).

## Score (10-point scale, strict)

| Area | Score | Basis |
| --- | --- | --- |
| First Impression | 8 | README answers stack/architecture/status in under 2 minutes; badges restrained |
| Terraform | 8 | Real plan reviewed by resource type, apply + destroy clean, version pins and module boundaries held on live AWS |
| AWS Architecture | 8 | No-NAT startup path proven end-to-end (pull, secret, logs) on first attempt; 2AZ placement and private-only tasks verified via API |
| Container | 8 | Build, healthy status, `/health` 200, and `/ready` against disposable PostgreSQL all executed today |
| Security | 8 | Roles/subnets/secret design verified on live AWS (task role zero policies, no public IPs, RDS private, 0 NAT); endpoint SG CIDR scope remains a documented trade-off |
| CI/CD | 7 | Non-AWS jobs green on GitHub (run 35333147317); OIDC/saved-plan/stability-wait design intact; AWS jobs unexecuted |
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

- GitHub Actions AWS jobs (plan on PR, deploy dispatch): NOT RUN — no standing OIDC credentials by design for this disposable validation.
- tflint / Trivy locally: NOT RUN — both PASS on GitHub Actions and (for Trivy) unneeded locally.
- Cost behavior beyond listing: metered only for one short session; environment destroyed same day.
- Everything else on the release gate is verified (see "AWS validation" above).

## Critical / High issues

- Critical: none in static review, none discovered during live deploy/destroy.
- High items from the static review, all closed by execution 2026-09-18:
  1. ~~No real AWS plan reviewed~~ — 60-add plan reviewed by resource type (no NAT/EIP, no updates/destroys).
  2. ~~No deployment/HTTP/RDS evidence~~ — stable 2/2 service, healthy targets, `/health` + `/ready` 200, RDS available/private.
  3. GitHub Actions AWS jobs never executed — remains NOT RUN (no standing credentials); non-AWS CI jobs green. Not a code defect.
- Previously open High items closed in code this review cycle: `id-token: write` scoped to the plan job; deploy workflow now plans/saves, shows, applies the same artifact, waits for `services-stable`, and smoke-tests `/health`; root outputs `ecs_cluster_name`/`ecs_service_name` added for verification; README validation matrix + badges added.

## Evaluated and intentionally not changed

- Endpoint SG allows 443 from the VPC CIDR instead of referencing the ECS SG. Passing the root ECS SG into the network module would create a dependency cycle (root SGs need the module's `vpc_id`). The correct fix is relocating the endpoint SG beside its consumers — a refactor disproportionate to the gain in a single-workload VPC. Kept as a documented trade-off in `docs/AUDIT.md` and `docs/INTERVIEW_GUIDE.md` Q10.

## Changes made (this review cycle)

1. `docs/AUDIT.md`: created — severity-graded findings plus the no-NAT runtime-path trace.
2. `.github/workflows/ci.yml`: least-privilege `id-token` scoping to the plan job; fixed unresolvable `trivy-action@0.33.1` → `v0.33.1`, then bumped to `v0.36.0` (v0.65.0 binary gone).
3. `.github/workflows/deploy.yml`: saved-plan apply, `services-stable` wait, `/health` smoke test.
4. `infra/outputs.tf`: verification outputs for cluster/service names.
5. `README.md`: real CI status badge (replacing the stale "not yet executed" badge), validation snapshot, NAT/liveness/bootstrap/approval trade-offs.
6. `.gitignore`: cover bare `tfplan` / `destroy.tfplan` plan files.
7. `docs/VALIDATION.md`: full lifecycle record — local results, CI evidence, real plan/apply/verify/game-day/destroy with API-verified cleanup.
8. `docs/INTERVIEW_GUIDE.md`: created — 29 implementation-grounded Q&A.
9. `docs/PUBLICATION_REPORT.md`: this file.

## Strongest portfolio points

- Honest verification boundary: PASS / BLOCKED / NOT RUN never mixed.
- No-NAT startup path traced hop by hop, with cost caveat instead of a cheapness claim.
- Execution/task role separation proven by a dedicated incident scenario.
- Liveness vs readiness reasoning that prevents restart amplification.
- Change safety made visible: immutable SHA tags, saved-plan apply, approval gate, plan checklist.

## Weakest portfolio points

- AWS CI jobs (plan/dispatch-deploy) unexecuted; OIDC trust never authenticated with standing credentials.
- SLO implementation is a symptom alarm, not burn-rate alerting; no deployment-failure event alarm.
- Single-AZ RDS default bounds every availability claim.
- tflint/Trivy evidence exists only on CI runners, not locally.
- No production traffic history: thresholds remain starting hypotheses.

## Questions likely to be asked in interviews

Covered in depth in `docs/INTERVIEW_GUIDE.md`. The five most probable: NAT-less ECR pull path; execution vs task role; why ALB checks liveness not readiness; S3 `use_lockfile` vs DynamoDB; why apply is manual and plan-gated.

## Recommended next actions (in order)

1. Flip the repo to public whenever ready; keep this report and VALIDATION.md linked from the README.
2. Optional: credentialed PR-plan run to exercise the OIDC path.
3. Add deployment-failure event alerting and multi-window burn-rate alarms.
4. Re-validate on the next Terraform/AWS-provider major bump (plan + short deploy/destroy).

## Ready for public GitHub?

Yes — the platform was deployed to real AWS on 2026-09-18, verified end-to-end, and destroyed the same day with API-verified cleanup. Claims match executed evidence throughout.
