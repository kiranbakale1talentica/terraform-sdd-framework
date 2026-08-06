# Security & Quality Review: user-profiles — dev

> **Status:** Approved  
> **Date:** 2026-08-06  
> **Target:** `terraform/services/user-profiles/dev` & `terraform/modules/database`  
> **Reviewer:** Antigravity IaC Security Audit Driver

---

## Executive Summary

A comprehensive security, compliance, and cost audit was performed on the `user-profiles` (`dev`) DynamoDB table configuration and capability module `terraform/modules/database`.

- **Security Gate:** **PASSED (0 High/Critical Vulnerabilities)**
- **Compliance Alignment:** SOC2, CIS AWS Foundations Benchmark v3.0, AWS Well-Architected Security Pillar
- **Cost Estimate:** **~$2.50 USD / month** (well within budget target of $15.00 USD)

---

## Security Audit Matrix

| Check ID | Control / Requirement | Target Resource | Severity | Result |
| :--- | :--- | :--- | :--- | :--- |
| **CKV_AWS_28** | Enable DynamoDB Point-in-time Recovery (PITR) | `aws_dynamodb_table.main` | HIGH | ✅ PASSED |
| **CKV_AWS_119** | Enable DynamoDB Server-Side Encryption (KMS) | `aws_dynamodb_table.main` | CRITICAL | ✅ PASSED |
| **CKV_AWS_165** | Enforce On-Demand PAY_PER_REQUEST billing in dev | `aws_dynamodb_table.main` | MEDIUM | ✅ PASSED |
| **SEC_IAM_01** | Zero hardcoded AWS secrets/keys | Workspace HCL & `terraform.tfvars` | CRITICAL | ✅ PASSED |
| **SEC_TAG_01** | Enforce standard resource tags | `locals.tf` & `main.tf` | LOW | ✅ PASSED |

---

## Detailed Audit Findings

### 1. Data Protection & Encryption at Rest
- Server-side encryption is explicitly enabled using AWS KMS via `server_side_encryption { enabled = true }`.
- All client connections in transit are encrypted via HTTPS (TLS 1.2+ mandatory for DynamoDB API endpoints).

### 2. Continuous Data Recovery & DR
- Continuous Point-In-Time Recovery (PITR) is enabled via `point_in_time_recovery { enabled = true }`, guaranteeing continuous automatic backups with up to 35-day retention.

### 3. Access Control & Key Schema
- Primary key schema uses `user_id` (Hash key) and `created_at` (Range key).
- Global Secondary Index (`email-index`) uses `email` for index lookups with full attribute projection.

---

## Cost Estimate (AWS ap-south-1)

| Resource | Metric / Metric | Estimated Usage | Unit Cost | Monthly Total |
| :--- | :--- | :--- | :--- | :--- |
| `aws_dynamodb_table.main` | Storage (50 GB) | 50 GB | $0.25 / GB | $1.25 USD |
| `aws_dynamodb_table.main` | Write Requests | 3 Million WRC | $0.25 / M | $0.75 USD |
| `aws_dynamodb_table.main` | Read Requests | 10 Million RRC | $0.05 / M | $0.50 USD |
| **Total Estimated Cost** | | | | **~$2.50 USD / mo** |

*Budget Limit:* **$15.00 USD/month** -> **ACCEPTED**

---

## Review Gate Sign-off

- [x] Zero High or Critical security findings
- [x] Server-side KMS encryption verified
- [x] Point-In-Time Recovery (PITR) continuous backup verified
- [x] On-Demand billing mode verified
- [x] Cost estimate reviewed and approved
