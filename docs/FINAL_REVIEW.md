# Senior SRE / Platform Engineering review

> Superseded in part: this review was written before the real AWS validation. The deployment, verification, game-day, and destroy evidence from 2026-09-18 — and the current **READY** verdict — are recorded in [the publication report](PUBLICATION_REPORT.md) and [the validation record](VALIDATION.md). The design analysis below remains accurate.

## Publication decision

**Not yet ready for public claims of a deployed, end-to-end validated platform.** Static implementation quality is suitable for private review, but the High findings below must be closed first.

## Findings

### Critical

None identified in the static review.

### High

| Finding | Risk | Required closure evidence |
| --- | --- | --- |
| No real AWS plan has been reviewed | Provider/API constraints or unintended changes may remain | Saved plan plus completed review checklist in an isolated account |
| No ECS/RDS deployment or HTTP verification | Network, IAM secret injection, and startup are not proven together | Stable deployment, healthy targets, `/health` 200 and `/ready` 200 |
| GitHub Actions has not run | OIDC, state access, analysis tools, and approval controls may be wrong | Green PR CI and approval-gated deployment run |

### Medium

| Finding | Concern | Follow-up |
| --- | --- | --- |
| Public endpoint is HTTP | Traffic lacks confidentiality/integrity | Add Route 53, ACM, HTTPS, and redirect before non-demo use |
| RDS defaults to Single-AZ | Database is the primary availability gap | Evaluate Multi-AZ against cost and SLO |
| No service autoscaling | Capacity does not react to load | Add bounded target tracking after measuring workload |
| SLO alarm is a short-window approximation | It is not multi-window burn-rate alerting | Record valid/total events and add burn-rate alarms |
| No deployment-failure event alarm | Pre-start failures may rely on observation | Route ECS deployment state events to an actionable destination |

### Low

- Application functionality is intentionally minimal and has only health/readiness tests.
- Alarm thresholds require tuning with traffic and database limits.
- Documentation is English-first; prepare a concise Japanese walkthrough.

## Strong portfolio signals

- The design is small enough to explain but covers infrastructure, release, observability, and response as one system.
- Trust boundaries and SG-to-SG paths are explicit.
- Execution role and task role responsibilities are deliberately separated.
- Image identity and Terraform plan review make change safety visible.
- Native Terraform mock-plan tests preserve the two-AZ, SG-chain, bootstrap-count, and S3-endpoint contracts without AWS credentials.
- Liveness/readiness behavior shows awareness of failure amplification.
- Container and IaC scans have no unsuppressed High/Critical findings; explicit exceptions remain documented in code and README.
- Incident documents describe evidence-driven narrowing rather than jumping to an answer.
- Limitations and production gaps are stated without inflated claims.

## Design decisions to explain in an interview

1. Why endpoint-only private egress was chosen and when NAT would be better.
2. Why the ALB uses liveness instead of database readiness.
3. Why the first apply creates a service with desired count zero.
4. Why RDS is Single-AZ by default despite a 99.9% learning SLO.
5. Which actor uses the execution role versus task role during secret injection.
6. Why apply is approval-gated while plan is generated on pull requests.

## Likely interview questions

- How would schema migrations be sequenced with deployment and rollback?
- What happens when RDS rotates the master secret while tasks are running?
- How would you alert on no healthy capacity or a failed deployment?
- How would you reduce endpoint cost without exposing private tasks?
- How would you prove the SLI when ALB metrics are missing or traffic is low?
- What Terraform changes can replace RDS, and how is data protected?
- How would state access be separated between dev and production accounts?

## Scope that must be described as personal validation

Terraform, the container pipeline, alarms, SLI/SLO, incident simulations, and postmortem are personal portfolio work until real execution evidence is added. Professional AWS/CDK experience can be discussed separately, but this repository must not be described as a production system operated for an employer.
