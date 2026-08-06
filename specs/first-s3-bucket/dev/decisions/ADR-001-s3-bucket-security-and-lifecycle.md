# ADR-001: S3 Bucket Security, Versioning, and Lifecycle Standard

- **Status:** Accepted
- **Deciders:** DevOps Team
- **Date:** 2026-08-06

---

## Context and Problem Statement

When creating object storage infrastructure in AWS, raw S3 buckets default to settings that might inadvertently expose data or lack lifecycle protection. We need a standard security posture for all S3 storage buckets provisioned in this repository.

## Decision Drivers

- Prevent accidental data exposure to the public internet.
- Ensure all stored data is encrypted at rest automatically.
- Prevent data loss from accidental deletion via object versioning.
- Optimize storage costs by auto-transitioning stale object versions.

## Considered Options

1. **Option 1:** Unencrypted/Public default S3 bucket.
2. **Option 2 (Chosen):** Secure S3 bucket with default-deny Public Access Block, SSE-S3 AES256 encryption, bucket versioning, and Standard-IA lifecycle transition rules.

## Decision Outcome

Chosen Option: **Option 2**.

### Positive Consequences
- **Security:** Complete isolation with `block_public_acls = true`, `block_public_policy = true`, `ignore_public_acls = true`, `restrict_public_buckets = true`.
- **Compliance:** Meets SOC2 and security benchmark audit requirements out-of-the-box.
- **Cost Efficiency:** Older non-current object versions automatically transition to Standard-IA after 30 days.

### Negative Consequences
- Slightly increased storage overhead for keeping non-current versions until lifecycle transition.
