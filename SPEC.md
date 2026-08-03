# Master Specification: Terraform SDD Framework

> **Specification Reference for Infrastructure Architecture, CI/CD Standards, and Workload Patterns.**

---

## 1. Executive Summary

This document serves as the **Master Specification (`SPEC.md`)** for the Terraform Specification Driven Development (SDD) framework. It establishes the architectural constraints, tool requirements, security models, and standard deployment patterns enforced across all cloud infrastructure generated within this repository.

---

## 2. Target Technology Stack & Assumptions

| Component | Standard Technology | Specification / Implementation |
|-----------|--------------------|--------------------------------|
| **Cloud Provider** | AWS (Amazon Web Services) | Primary cloud target |
| **CI/CD Platform** | GitHub Actions | Workflows in `.github/workflows/` |
| **Auth & Identity** | AWS OpenID Connect (OIDC) | Keyless IAM AssumeRole authentication |
| **IaC Tooling** | HashiCorp Terraform (`>= 1.6.0`) | HCL2 with pessimistic version constraints |
| **Linting & Policy** | TFLint + Checkov / tfsec | Static policy scanning in PR pipelines |
| **Frontend Workload** | React / SPA / Static | AWS S3 (Private) + CloudFront CDN + OAC |
| **Backend Workload** | Node.js / Python REST APIs | AWS ECS Fargate + ALB + RDS PostgreSQL |

---

## 3. Workload Architecture Specifications

### 3.1 Frontend Hosting Specification (React / Single Page App)

When a workload type is `frontend-hosting` (e.g., React, Vue, Next.js static export):

```
 ┌──────────────┐      HTTPS       ┌────────────────────────┐      OAC (Private)      ┌────────────────────────┐
 │   User /     │ ───────────────> │  AWS CloudFront CDN    │ ──────────────────────> │  AWS S3 Bucket         │
 │   Browser    │  Custom Domain   │  (Edge Caching & TLS)  │   Origin Access Control │  (Static Build Assets) │
 └──────────────┘                  └────────────────────────┘                         └────────────────────────┘
                                               │
                                               ▼
                                   ┌────────────────────────┐
                                   │  AWS Route53 + ACM     │
                                   │  (DNS & SSL Cert)      │
                                   └────────────────────────┘
```

#### Mandatory Requirements:
1. **S3 Bucket:** Must be private (`block_public_acls = true`, `block_public_policy = true`, `ignore_public_acls = true`, `restrict_public_buckets = true`).
2. **CDN Access:** Direct S3 web hosting is disabled. Access to S3 is allowed **only** via CloudFront Origin Access Control (OAC).
3. **TLS/SSL:** Enforce TLS 1.2+ using AWS Certificate Manager (ACM) certificates.
4. **Routing:** SPA fallback rules configured in CloudFront (`404` and `403` HTTP errors redirect to `/index.html` with status `200`).
5. **Security Headers:** Enforce Response Headers Policies on CloudFront (`Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`).

---

### 3.2 Backend API Specification (ECS Fargate + RDS)

When a workload type is `container-service` or `backend-api`:

```
 ┌──────────────┐     HTTPS (443)     ┌────────────────────────┐    Private Subnet    ┌────────────────────────┐
 │   User /     │ ──────────────────> │ Application Load       │ ───────────────────> │  AWS ECS Fargate       │
 │   Client     │                     │ Balancer (ALB)         │                      │  (Container Tasks)     │
 └──────────────┘                     └────────────────────────┘                      └────────────────────────┘
                                                                                                  │
                                                                                            Database Security
                                                                                                  Group
                                                                                                  ▼
                                                                                      ┌────────────────────────┐
                                                                                      │  AWS RDS PostgreSQL    │
                                                                                      │  (Isolated Subnets)    │
                                                                                      └────────────────────────┘
```

#### Mandatory Requirements:
1. **VPC Subnet Layout:**
   - **Public Subnets:** Internet Gateways + ALB only.
   - **Private Subnets:** NAT Gateways + ECS Fargate Tasks (no public IP assignments).
   - **Data Subnets:** Isolated subnets with no internet routes for RDS databases.
2. **IAM Roles:** Separate Task Execution Role (Pull image, CloudWatch logs) and Task Role (Application permissions).
3. **Database Security:** Enforce encryption at rest (KMS), automatic backups, and database placement strictly in Data subnets.

---

## 4. Security & Authentication Specification

### 4.1 AWS OIDC Authentication for GitHub Actions

All CI/CD operations MUST authenticate using AWS OIDC. Long-lived credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are prohibited.

#### IAM Role Trust Policy Specification:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG>/<REPO_NAME>:*"
        }
      }
    }
  ]
}
```

---

## 5. Specification Driven Development (SDD) Lifecycle Gates

Every change in this framework must adhere to the 6-phase gated lifecycle:

```
┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐
│  /spec  │ ───> │  /plan  │ ───> │  /build │ ───> │  /test  │ ───> │ /review │ ───> │  /ship  │
└─────────┘      └─────────┘      └─────────┘      └─────────┘      └─────────┘      └─────────┘
  Discovery        Architecture     Terraform        Fmt/Lint/        Security         Deployment
  Interview        & ADRs           Generation       Validate         & Cost           Readiness
```

1. **`/spec` Gate:** `infrastructure-spec.yaml` complete & approved.
2. **`/plan` Gate:** `architecture.md` & ADRs written.
3. **`/build` Gate:** Terraform HCL generated following HashiCorp style guide.
4. **`/test` Gate:** Clean `fmt`, `validate`, `tflint`, and `terraform test`.
5. **`/review` Gate:** Checkov security scan clean & cost estimated.
6. **`/ship` Gate:** `deployment-readiness.md` signed off; GitHub Actions apply executed.

---

## 6. Required Resource Tags

All AWS resources generated by this framework MUST include the following default tags:

```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = var.service_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}
```
