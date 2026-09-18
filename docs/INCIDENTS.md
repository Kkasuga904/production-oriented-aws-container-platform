# Incident simulations

These are controlled game-day scenarios. Commands that intentionally break infrastructure must only run in a disposable environment with an approved rollback.

## Incident 1: ALB target unhealthy

### Symptom

ALB returns 503 and `UnHealthyHostCount` increases after a deployment.

### User impact

Requests cannot reach a healthy API task. Impact can be partial during a rolling deployment or complete if every target fails.

### Detection

The unhealthy-target alarm fires. The deployment circuit breaker reports a failed rollout. Target-group health reasons and ECS service events provide the first diagnostic evidence.

### Initial hypotheses

1. The process does not listen on port 8000.
2. `/health` no longer returns HTTP 200.
3. ALB-to-ECS security-group traffic is blocked.
4. The task is restarting before registration.

### Investigation

1. Correlate alarm time with the ECS deployment and task-definition revision.
2. Inspect target health reason codes rather than assuming an application failure.
3. Check ECS desired/running/pending counts and stopped-task reasons.
4. Inspect `/ecs/<name>` logs for process startup and health-handler errors.
5. Compare target-group port/path/matcher with container port and route.
6. Review the Terraform plan for SG or target-group changes.

### Root cause used in the simulation

Deploy a branch that changes the application listen port without updating the task and target-group contract.

### Resolution

Roll back to the previous task-definition revision/image SHA and verify two consecutive healthy checks.

### Permanent fix

Keep the port contract in one reviewed module interface and run a container smoke test against `/health` in CI.

### Prevention

Require plan/deployment review, preserve immutable image tags, and test the exact container entrypoint before push.

## Incident 2: ECS cannot connect to RDS

### Symptom

`/health` succeeds but `/ready` returns 503. Requests that require persistence fail while the container remains alive.

### User impact

Database-backed operations fail. A liveness-only ALB health check intentionally avoids a restart storm, so dependency degradation must be detected separately.

### Detection

Application 5xx increases while targets remain healthy. Application logs show sanitized connection failures; RDS connection count may fall unexpectedly.

### Initial hypotheses

1. DNS or endpoint value is wrong.
2. ECS egress or RDS ingress on TCP/5432 changed.
3. RDS is unavailable or restarting.
4. Credentials rotated but the task still has stale injected values.
5. TLS/database-name configuration is wrong.

### Investigation

1. Establish whether failures are timeout, refused connection, authentication, or TLS errors.
2. Check RDS status/events and CloudWatch CPU/connections.
3. Compare task environment host/port with the RDS endpoint.
4. Review both SG rule directions and VPC/subnet placement.
5. Use an approved ECS diagnostic task in the same SG to test DNS and TCP/5432; do not expose RDS publicly.
6. Compare the last successful deployment and Terraform plan.

### Root cause used in the simulation

Remove the `database_from_ecs` ingress rule in a game-day branch.

### Resolution

Restore the SG-to-SG ingress rule, apply the reviewed plan, and verify `/ready` plus a real query.

### Permanent fix

Add policy-as-code assertions for public RDS access and the intended SG relationship, plus a post-deploy readiness canary.

### Prevention

Treat SG changes as high risk in plan review and attach a time-bounded rollback owner to the change.

## Incident 3: Secrets Manager AccessDenied

### Symptom

New tasks stop during initialization with a resource-initialization error; old tasks may continue serving.

### User impact

Deployments stall and capacity can fall if old tasks terminate. Existing capacity may hide the fault until scaling or replacement.

### Detection

ECS service events and stopped-task reasons report secret retrieval failure. No application log appears because the container never starts.

### Initial hypotheses

1. Execution role lacks `secretsmanager:GetSecretValue`.
2. Permission was placed on the task role instead of the execution role.
3. Secret ARN or region is wrong.
4. Endpoint/DNS/SG prevents access to Secrets Manager.
5. A customer-managed KMS key also requires `kms:Decrypt`.

### Investigation

1. Read the ECS stopped reason and identify the task-definition revision.
2. Inspect the execution role and its exact secret ARN resource.
3. Confirm that the secret exists and that RDS still manages it.
4. Check the Secrets Manager VPC endpoint, private DNS, and TCP/443 path.
5. Use CloudTrail to distinguish an IAM deny from a missing network request.
6. If a customer-managed key is introduced, inspect its key policy and execution-role permission.

### Root cause used in the simulation

Change the execution-role resource ARN to a nonmatching secret.

### Resolution

Restore the exact secret ARN permission, register a new task revision if needed, and observe a successful rolling deployment.

### Permanent fix

Keep secret access colocated with the task definition and add an IAM simulation or deployment smoke test to the release path.

### Prevention

Review role separation explicitly and alert on failed ECS deployments rather than relying only on application metrics.
