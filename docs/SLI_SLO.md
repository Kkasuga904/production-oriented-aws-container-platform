# SLI, SLO, and error budget

## Availability

- **SLI:** requests completed without an ALB target 5xx response / total ALB requests.
- **Initial SLO:** 99.9% over a rolling 30-day window.
- **Error budget:** 0.1%, approximately 43 minutes of equivalent complete unavailability in 30 days.

The 99.9% target is intentionally a learning target, not a promise justified by user research. It creates enough sensitivity to demonstrate error-budget reasoning without claiming that a Single-AZ portfolio database can satisfy the target under every failure. In a real service, product impact, contractual expectations, dependency history, maintenance patterns, traffic shape, and the cost of redundancy would determine the objective.

## Latency

- **SLI:** ALB `TargetResponseTime` p95.
- **Initial SLO:** p95 below 500 ms over five-minute windows.

The API is deliberately small, so 500 ms is a conservative starting point that catches dependency stalls while allowing for cold starts and the low-cost database. Production objectives should be derived from user journeys and measured baselines. The health endpoint is excluded from product-latency analysis where log-based SLIs are available.

## Alerting approach

The Terraform alarm on 5xx rate is an immediately understandable short-window symptom alarm, not a complete SLO implementation. A production system should record valid/total event counts, use multi-window multi-burn-rate alerts, and store SLO history in a system that can distinguish low traffic, planned exclusions, and missing telemetry.

When the budget is healthy, normal feature delivery continues. Rapid budget consumption prioritizes reliability work and may pause risky changes. Exhausting the budget triggers an explicit product/engineering decision; it does not automatically assign blame.
