# ADR-001: Frontend Hosting Architecture

## Status

> **Accepted**

## Date

2026-08-04

## Authors

- DevOps Team

## Context

We need to provide a hosting environment for a simple, single-page "hello world" documentation portal. The solution must be highly available, fast globally, securely enforce HTTPS, and keep costs as low as possible. Additionally, the domain `kiranbakale.online` must be used, and security policies mandate that backend storage for static assets cannot be publicly accessible directly.

## Decision

We will use **AWS S3 for static asset storage**, fronted by **AWS CloudFront** configured with **Origin Access Control (OAC)** to securely fetch content from the S3 bucket.

## Alternatives Considered

### Option 1: AWS Amplify Hosting

**Description:** Use the managed AWS Amplify console to automatically build and host the static site from a Git repository.

**Pros:**
- Out-of-the-box CI/CD integration.
- Managed DNS and TLS certificates.

**Cons:**
- Abstracts away infrastructure components, offering less granular control over caching and security.
- Slightly higher cost at scale compared to raw S3/CloudFront.

**Rejected because:** We need granular control over the infrastructure (like CloudFront logging, OAC, and strict S3 policies) defined via Terraform in the SDD framework.

---

### Option 2: S3 Static Website Hosting (Direct)

**Description:** Use the native "Static website hosting" feature on the S3 bucket and point a Route53 alias directly to the bucket.

**Pros:**
- Extremely simple to set up.
- Zero compute cost; only pay for storage and bandwidth.

**Cons:**
- Cannot enforce HTTPS with a custom domain directly on S3.
- Requires the S3 bucket to have public read access, which violates our strict security requirements.

**Rejected because:** It violates the security requirement to strictly keep S3 private and enforce HTTPS on the custom domain.

---

### Option 3 (Chosen): AWS S3 + CloudFront with OAC

**Description:** Store files in a private S3 bucket and distribute them globally via CloudFront. Access to S3 is restricted exclusively to the CloudFront distribution using Origin Access Control (OAC).

**Pros:**
- Global edge caching for low latency.
- Enforces HTTPS at the edge with ACM certificates.
- S3 bucket remains strictly private (blocks public access entirely).
- Very low cost for low-traffic sites.

**Cons / Accepted Trade-offs:**
- CloudFront propagation takes a few minutes when updating caching behaviors or invalidating caches.
- Increased Terraform complexity (requires ACM validation, Route53, CloudFront, and S3 bucket policies).

**Selected because:** It is the industry standard for secure, low-cost static hosting on AWS and perfectly meets all security and cost requirements.

## Consequences

**Positive consequences:**
- The docs portal will be highly available and secure.
- We comply with security mandates (no public S3 buckets).
- Minimal ongoing costs.

**Negative consequences / Trade-offs:**
- CI/CD pipelines deploying content will need to explicitly create CloudFront invalidations if immediate content updates are required, as CloudFront will cache the static assets.

## Impact

| Area | Impact | Notes |
|------|--------|-------|
| Cost | Low | Only paying for S3 storage, basic CloudFront bandwidth, and Route53 queries. |
| Security | High | S3 is completely private; HTTPS is enforced. |
| Complexity | Medium | Requires coordinating Route53, ACM, CloudFront, and S3 policies in Terraform. |
| Reversibility | Easy | The static assets can easily be moved to another hosting provider if needed. |
| Timeline | none | Standard Terraform deployment. |

## Implementation Notes

- Must use `aws_cloudfront_origin_access_control` instead of the legacy Origin Access Identity (OAI).
- The ACM certificate must be provisioned in the `us-east-1` region for CloudFront to use it.
- Route53 records will need to use `aws_route53_record` with `alias` blocks pointing to the CloudFront distribution domain name.

## Review Date

2027-08-04
