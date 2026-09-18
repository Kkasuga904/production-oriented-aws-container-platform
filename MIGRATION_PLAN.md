# Migration Plan

## Decision

The previous Terraform project remains untouched as an audit reference. The new portfolio is implemented in a separate directory because correcting the old dependency graph would take roughly the same effort as a clean implementation while retaining confusing names and unsafe defaults.

| Existing component | Current quality | Reuse? | Reason | Action |
| --- | --- | --- | --- | --- |
| Root configuration | `terraform validate` fails and resources span unrelated VPCs | No | Hard-coded IDs and inconsistent module outputs make incremental repair risky | Rebuild with one explicit dependency graph |
| Network module | One public subnet; no IGW, routes, or private tier | Design reference only | It does not meet the two-AZ or private workload requirements | Implement a two-AZ VPC from scratch |
| EC2 module | Broken user-data path and EC2 does not fit the target architecture | No | The target runtime is ECS Fargate | Replace with ECS service and task definition |
| ALB module | Basic listener/target group structure is recognizable | Design reference only | One subnet, HTTP-only assumptions, and EC2 coupling need redesign | Implement ALB as part of the service module |
| S3 module | Versioning is enabled | No | Input is ignored and public-access/encryption controls are incomplete | Use S3 only in the independent state bootstrap |
| IAM module | Contains an unattached user policy and unused inputs | No | Does not model ECS execution/task role separation | Rebuild least-privilege roles with the workload |
| RDS module | No resource implementation; output references a nonexistent module | No | There is nothing safe to reuse | Implement private encrypted PostgreSQL |
| CloudWatch module | Shows a simple CPU alarm pattern | Concept only | Alarm is not connected to notification or service-level signals | Implement user/service/infrastructure alarm layers |
| `units` module | Tutorial/demo data and a globally fixed S3 name | No | No architectural responsibility | Remove |
| Architecture image | Communicates the former EC2 concept | No | It does not represent the new design | Replace with version-controlled Mermaid |
| README | Claims exceed what the code can demonstrate | No | A portfolio README must be evidence-based | Rewrite around decisions, validation, and limitations |

## Reuse classification summary

- **Reuse as-is:** none.
- **Reuse with small corrections:** none.
- **Reuse after redesign:** the conceptual ALB-to-compute flow and basic CloudWatch alarm idea only.
- **Safer/faster to implement anew:** network, runtime, database, IAM, state, CI/CD, application, and documentation.

## Migration risks

- No production data or Terraform state is migrated.
- Resource names are intentionally different, so this is not an in-place upgrade.
- The new configuration must first be deployed to an isolated AWS account or sandbox.
- The application image must exist in ECR before the first stable ECS rollout; the deployment workflow documents that bootstrap sequence.
