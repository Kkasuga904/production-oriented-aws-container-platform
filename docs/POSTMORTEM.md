# Postmortem: failed ECS deployment after secret permission regression

**Status:** simulation completed by design review; AWS game-day execution pending  
**Severity:** SEV-2 scenario  
**Authors:** Platform Engineering  

## Summary

A simulated IAM change removed the ECS execution role's access to the RDS-managed secret. New tasks could not retrieve `DB_SECRET_JSON`, so the deployment failed before the application process started. The deployment circuit breaker preserved the previous healthy revision.

## Impact

No real users were affected because this is a portfolio simulation. In the modeled event, new releases and replacement tasks are blocked. User traffic remains available only while the previous task set retains sufficient healthy capacity.

## Timeline

- 10:00 — IAM change approved and applied.
- 10:03 — New ECS deployment starts.
- 10:04 — Tasks stop with `ResourceInitializationError`.
- 10:05 — ECS deployment failure is observed in service events.
- 10:08 — On-call confirms there are no new application log streams.
- 10:12 — Execution-role policy diff reveals a nonmatching secret ARN.
- 10:17 — Policy is restored and a new deployment starts.
- 10:22 — Desired healthy count is restored.

## Detection

ECS service events detected the failure. The current portfolio does not yet create a dedicated alarm for failed deployments, which is a corrective action.

## Root cause

The execution-role policy no longer matched the secret ARN referenced by the task definition. Secret injection is performed by the ECS agent using the execution role, so the container never started.

## Contributing factors

- Review focused on the task role and did not explicitly verify the execution role.
- The release check expected application logs, but a pre-start failure creates none.
- No automated IAM simulation covered the secret retrieval contract.

## Resolution

The exact secret ARN was restored to the execution-role policy. The new task revision then retrieved the secret and passed container and ALB health checks.

## Corrective actions

| Action | Priority | Owner | Verification |
| --- | --- | --- | --- |
| Add a review item for execution-role versus task-role responsibility | High | Platform | PR template/checklist update |
| Alert on ECS deployment failure events | High | Platform | Controlled failed deployment |
| Add post-deploy desired/running-count and HTTP checks | High | Platform | Release workflow test |
| Evaluate IAM policy simulation for the exact secret ARN | Medium | Security | CI proof of expected allow |

## Prevention

IAM diffs are reviewed as interface changes, image tags remain immutable, and the previous revision is retained for rollback. A future release workflow should wait for service stability and verify both `/health` and `/ready`.

## Lessons learned

Absence of application logs can be evidence that failure occurred before process startup. Role ownership must be reasoned about from the actor performing the API call, not merely from the application that ultimately consumes the value. No individual action caused the modeled incident; the missing automated contract allowed the regression through review.
