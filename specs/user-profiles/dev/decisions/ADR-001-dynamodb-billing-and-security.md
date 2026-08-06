# ADR-001: DynamoDB Billing Mode, Security, and Backup Strategy

- **Status:** Accepted
- **Deciders:** DevOps Team
- **Date:** 2026-08-06

---

## Context and Problem Statement

We need a scalable, serverless NoSQL database table for user profiles in the `dev` environment. The database must provide low-latency reads/writes, guarantee data protection at rest, and scale dynamically without incurring unneeded costs when idle.

## Decision Drivers

- Eliminate fixed hourly costs for database capacity when idle in dev.
- Ensure all profile data is encrypted at rest automatically.
- Provide continuous backup capabilities to support quick point-in-time recovery.
- Enable fast secondary query lookups by user email address.

## Considered Options

1. **Option 1:** Provisioned Capacity Mode (`PROVISIONED` read/write capacity units).
2. **Option 2 (Chosen):** On-Demand Billing Mode (`PAY_PER_REQUEST`), KMS Encryption at rest, Point-In-Time Recovery (PITR) enabled, and `email-index` Global Secondary Index (GSI).

## Decision Outcome

Chosen Option: **Option 2**.

### Positive Consequences
- **Cost Efficiency:** `PAY_PER_REQUEST` ensures $0 compute cost when no requests are being served in `dev`.
- **Data Protection:** Server-side encryption via AWS KMS protects sensitive profile data at rest.
- **Resilience:** Continuous Point-In-Time Recovery (PITR) allows restoration to any second within the past 35 days.
- **Performance:** Sub-10ms latency for queries on both `user_id` and `email` lookups.

### Negative Consequences
- Slightly higher per-request cost for unpredictable spike workloads compared to heavily discounted reserved provisioned capacity (acceptable for dev workloads).
