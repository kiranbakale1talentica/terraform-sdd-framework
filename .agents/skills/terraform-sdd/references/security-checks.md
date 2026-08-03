# Security Review Checklist

> **Used by:** `/review` phase of the Terraform SDD skill  
> **Tools:** Checkov, tfsec, manual review  
> **Purpose:** Security standards that every Terraform configuration must meet before `/ship`

---

## How to Use This Checklist

1. Run automated security scans first (Checkov, tfsec)
2. Review all HIGH and CRITICAL findings — fix or document exceptions
3. Run through the manual checklist sections below
4. Document exceptions with justification in `validation/security-report.md`

**No HIGH or CRITICAL unresolved findings may reach `/ship`.**

---

## Automated Scanning

### Checkov

```bash
# Full scan with output
checkov -d . --framework terraform

# JSON report for CI
checkov -d . --framework terraform \
  --output json \
  --output-file-path validation/

# Soft-fail (CI continues, but report is produced)
checkov -d . --framework terraform --soft-fail

# Exclude specific checks (document the reason)
checkov -d . --framework terraform \
  --skip-check CKV_AWS_20,CKV_AWS_57
```

### tfsec

```bash
# Standard scan
tfsec .

# JSON report
tfsec . --format json --out validation/tfsec-report.json

# With minimum severity
tfsec . --minimum-severity HIGH
```

### Trivy (optional, for comprehensive IaC scanning)

```bash
trivy config .
```

---

## Security Checklist by Category

### 1. Network Exposure

#### Public Access

- [ ] No resource is publicly internet-accessible unless explicitly required by the spec and documented in an ADR
- [ ] Security groups / NSGs do not allow `0.0.0.0/0` on management ports (SSH 22, RDP 3389)
- [ ] Load balancers exposed to the internet have WAF or rate limiting configured
- [ ] S3 buckets have `block_public_acls = true` and `block_public_policy = true` unless serving static websites (document if exception)
- [ ] Azure Blob containers are not set to `container` or `blob` access level unless intentional
- [ ] GCS buckets are not publicly accessible unless serving static content

#### Network Segmentation

- [ ] Compute resources are in private subnets (no public IPs by default)
- [ ] Databases are in isolated data subnets, not accessible from public subnets
- [ ] Security groups follow least-privilege: specific CIDR ranges and ports, not `0.0.0.0/0:0-65535`
- [ ] VPC flow logs are enabled
- [ ] Network ACLs are configured for stateless traffic filtering at subnet boundaries

---

### 2. Identity and Access Management

#### Least Privilege

- [ ] IAM roles/policies do not use `"Action": "*"` or `"Resource": "*"` without justification
- [ ] Service accounts / IAM roles are scoped to the specific service that uses them
- [ ] No IAM users with programmatic access keys (use IAM roles + instance profiles / IRSA / Workload Identity)
- [ ] Root account / owner account is not used for service operations
- [ ] MFA is required for privileged IAM operations (if configurable via Terraform)
- [ ] Cross-account roles have explicit trust policies with condition keys

#### Instance Profiles / Workload Identity

- [ ] EC2 instances use IAM instance profiles (not embedded credentials)
- [ ] EKS pods use IRSA (IAM Roles for Service Accounts)
- [ ] GKE workloads use Workload Identity (not service account key files)
- [ ] Azure workloads use Managed Identities (not service principal secrets in environment variables)

---

### 3. Data Encryption

#### Encryption at Rest

- [ ] All S3 buckets have server-side encryption enabled (SSE-S3 minimum; SSE-KMS preferred)
- [ ] All RDS instances have `storage_encrypted = true`
- [ ] All DynamoDB tables have encryption enabled
- [ ] All EBS volumes have encryption enabled
- [ ] Azure Storage accounts have infrastructure encryption enabled
- [ ] GCS buckets use CMEK where data classification requires it
- [ ] Kubernetes secrets are encrypted at rest (etcd encryption)
- [ ] Log storage is encrypted

#### Encryption in Transit

- [ ] All load balancers redirect HTTP → HTTPS
- [ ] TLS certificates are valid and managed (ACM / Key Vault / Certificate Manager)
- [ ] Minimum TLS version is 1.2 (prefer 1.3)
- [ ] RDS instances have `parameter_group` with `ssl_mode` enforced
- [ ] ElastiCache clusters use encryption in transit and at rest
- [ ] Service-to-service communication uses TLS where crossing network boundaries

#### Key Management

- [ ] Customer-managed keys (CMK/CMEK) are used for highly sensitive data (per compliance requirement)
- [ ] Key rotation is enabled for CMKs
- [ ] KMS key policies follow least privilege
- [ ] Keys are not shared across environments

---

### 4. Secrets Management

- [ ] No passwords, tokens, API keys, or connection strings are in `.tf` files, `.tfvars` files, or environment variables in CI
- [ ] Secrets are stored in a secrets manager (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
- [ ] Secrets are referenced as data sources at apply time, not stored in state as plaintext where avoidable
- [ ] Sensitive Terraform outputs are marked `sensitive = true`
- [ ] `.terraform.tfstate` and `*.tfstate` files are in `.gitignore`
- [ ] `terraform.tfvars` containing secrets (even in templates) is in `.gitignore`
- [ ] CI/CD pipelines use secret injection (GitHub Secrets, Azure Key Vault pipeline integration, GCP Secret Manager)

---

### 5. Logging and Audit

- [ ] CloudTrail / Azure Activity Log / GCP Cloud Audit Logs is enabled in all regions
- [ ] CloudTrail has log file validation enabled
- [ ] CloudTrail logs are delivered to S3 with MFA delete enabled
- [ ] VPC flow logs are enabled and retained for compliance period
- [ ] S3 access logging is enabled for sensitive buckets
- [ ] Application load balancer access logs are enabled
- [ ] Database audit logs are enabled (audit_log for MySQL; pg_audit for PostgreSQL)
- [ ] Log retention matches compliance requirements

---

### 6. Compute Security

#### Containers

- [ ] Container images are from trusted registries (private registry preferred)
- [ ] Containers do not run as root (user specified in Dockerfile / pod security context)
- [ ] Container images are scanned for vulnerabilities before deployment
- [ ] ECR / ACR / Artifact Registry image scanning is enabled
- [ ] ECS task definitions do not have `privileged: true` unless documented
- [ ] Kubernetes pods have security contexts defined (`runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`)

#### VMs

- [ ] EC2 instances do not have public IP addresses unless explicitly required
- [ ] EC2 instance metadata service v2 (IMDSv2) is enforced (`metadata_options { http_tokens = "required" }`)
- [ ] SSH access is through a bastion host or SSM Session Manager, not direct internet exposure
- [ ] Security groups for EC2 do not allow SSH from `0.0.0.0/0`
- [ ] OS-level patching strategy is documented

#### Serverless

- [ ] Lambda functions have VPC configuration if accessing private resources
- [ ] Lambda execution roles follow least privilege
- [ ] Lambda environment variables do not contain secrets (use Secrets Manager references)
- [ ] Lambda functions have resource-based policies reviewed

---

### 7. Storage Security

- [ ] S3 versioning is enabled for buckets holding critical data
- [ ] S3 MFA delete is enabled for state and critical data buckets
- [ ] S3 lifecycle policies prevent indefinite data accumulation
- [ ] S3 replication is configured for disaster recovery buckets
- [ ] Azure Blob soft delete is enabled
- [ ] GCS object versioning is enabled for critical buckets

---

### 8. Database Security

- [ ] RDS instances are not publicly accessible (`publicly_accessible = false`)
- [ ] RDS has automated backups enabled with appropriate retention
- [ ] RDS deletion protection is enabled for production
- [ ] RDS enhanced monitoring is enabled
- [ ] RDS performance insights is enabled
- [ ] Database passwords are rotated via Secrets Manager
- [ ] Read replicas use the same encryption as primary

---

### 9. Compliance and Governance

- [ ] All resources have required tags (Project, Environment, ManagedBy, Owner, CostCenter)
- [ ] Resource-level access logging is enabled for compliance-sensitive resources
- [ ] Data residency — resources are deployed only in approved regions
- [ ] AWS Config / Azure Policy / GCP Organization Policy is configured for guardrails
- [ ] Cost anomaly detection is enabled
- [ ] Billing alerts are configured

---

## Common Checkov Rules Reference

| Rule ID | Description | Severity |
|---------|-------------|---------|
| CKV_AWS_20 | S3 bucket has public access | HIGH |
| CKV_AWS_21 | S3 versioning not enabled | LOW |
| CKV_AWS_57 | S3 bucket has object-level logging | MEDIUM |
| CKV_AWS_130 | S3 lifecycle not configured | LOW |
| CKV_AWS_23 | CloudFront not using HTTPS | HIGH |
| CKV_AWS_86 | CloudFront access logs enabled | LOW |
| CKV_AWS_2 | ALB HTTP listener not redirected to HTTPS | HIGH |
| CKV_AWS_91 | Kinesis encrypted | HIGH |
| CKV_AWS_17 | RDS publicly accessible | HIGH |
| CKV_AWS_16 | RDS encryption | HIGH |
| CKV_AWS_129 | RDS logging | MEDIUM |
| CKV_AWS_25 | Security group allows unrestricted ingress on port 22 | HIGH |
| CKV_AWS_24 | Security group allows unrestricted ingress on port 3389 | HIGH |
| CKV_AWS_8 | EC2 no public IP | MEDIUM |
| CKV_AWS_79 | EC2 IMDSv2 required | HIGH |
| CKV_AWS_7 | KMS key rotation | MEDIUM |
| CKV_AWS_111 | IAM policy allows * | HIGH |
| CKV_AWS_40 | IAM user has policies attached | MEDIUM |
| CKV_AWS_50 | Lambda function has tracing | LOW |
| CKV_AWS_119 | DynamoDB KMS encryption | HIGH |
| CKV_AWS_28 | ElastiCache encryption in transit | HIGH |

---

## Security Exception Documentation

When a security check cannot be remediated, document it:

```markdown
## Security Exception

**Check:** CKV_AWS_20 — S3 bucket has public access
**Resource:** `aws_s3_bucket.website`
**Reason:** This bucket serves the public-facing static website. Public read access is required by design.
**Mitigations:**
  - CloudFront OAC is configured; direct S3 access is blocked except for CloudFront
  - S3 access logging is enabled
  - WAF is attached to the CloudFront distribution
**Approved by:** [name/team]
**Review date:** [date]
```

Store exceptions in `validation/security-report.md`.
