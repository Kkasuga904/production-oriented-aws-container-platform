# Terraform plan review checklist

- [ ] The create/update/replace/destroy totals match the change request.
- [ ] No unrelated resource changes appear in the plan.
- [ ] Every replacement is understood, especially ECS services, ALB, subnet, and RDS resources.
- [ ] No unexpected destroy action or data-loss path exists.
- [ ] IAM actions, resources, and trust policies remain least-privilege.
- [ ] Security-group changes preserve the Internet → ALB → ECS → RDS path only.
- [ ] Database engine, storage, snapshot, deletion-protection, and secret changes are intentional.
- [ ] Backend/workspace/state moves are explicitly planned and backed up.
- [ ] Sensitive values are not rendered in logs or PR comments.
- [ ] The application image tag identifies an immutable build.
- [ ] Rollback is described and accounts for irreversible schema/data changes.
- [ ] The reviewer has identified who approves destructive or production changes.
