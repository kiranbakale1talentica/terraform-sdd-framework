# Deployment Readiness: docs-portal — dev

> **Service:** docs-portal  
> **Environment:** dev  
> **Terraform Plan:** [terraform-plan.md](../../plans/docs-portal/dev/terraform-plan.md)  
> **Validation:** [terraform-report.md](../../validation/terraform-report.md)  
> **Security Report:** [code-review-results.md](../../../code-review-results.md)  
> **Date:** 2026-08-04

---

## Pre-Flight Checklist

### Code Quality

- [x] `terraform fmt -recursive -check` — exit code 0, zero diff
- [x] `terraform validate` — exit code 0 in all roots and modules
- [x] `tflint --recursive` — zero errors
- [x] All variables have `type` and `description`
- [x] All outputs have `description`
- [x] No hardcoded secrets, account IDs, IP addresses, or region names
- [x] `terraform.tfvars` does not contain sensitive values

### Terraform Plan Review

- [ ] `terraform plan` has been run against target environment (Blocked: Invalid AWS Credentials)
- [ ] Plan output saved to `plans/docs-portal/dev/terraform-plan-output.txt`
- [ ] Plan output reviewed — no unexpected resource additions, modifications, or destructions
- [ ] Resource count matches expected (see terraform-plan.md resource inventory)
- [ ] No resources with `forces replacement` unless intentional and approved
- [ ] Cost estimate reviewed (see Section: Cost)

> [!WARNING]  
> Terraform is unable to generate the final execution plan or apply the changes because the current environment does not have valid AWS credentials configured (`InvalidClientTokenId` on STS `GetCallerIdentity`). A human or CI/CD runner must assume the correct AWS Role and run `terraform plan` and `terraform apply`.

### Security

- [x] Checkov scan complete — zero unresolved HIGH or CRITICAL findings
- [x] tfsec scan complete — zero unresolved HIGH findings
- [x] All security exceptions documented in `validation/security-report.md`
- [x] No resources with unexpected public internet access
- [x] No secrets in Terraform state (or all sensitive are marked `sensitive = true`)
- [x] IAM roles reviewed for least-privilege

### State Management

- [ ] Remote backend configured (Currently set to `local` for dev purposes. Recommendation: migrate to S3 backend before production).
- [ ] State file path: `services/docs-portal/dev/terraform.tfstate`
- [x] `.gitignore` covers `*.tfstate`, `*.tfstate.backup`, `.terraform/`

---

## Cost Estimate

| Resource | Monthly Estimate (USD) | Notes |
|---------|----------------------|-------|
| S3 Assets Bucket | ~$0.50 | Dependent on storage size and traffic |
| S3 Logs Bucket | ~$0.10 | Dependent on CloudFront log volume |
| CloudFront CDN | ~$0.00 | AWS Free Tier provides 1TB out/mo for first year |
| ACM Certificate | $0.00 | Public certificates are free |
| Route53 Record | $0.50 | Standard Hosted Zone cost + queries |
| **Total Estimate** | **~$1.10** | **Highly cost-effective for static hosting** |

**Budget:** Keep costs low (from spec)  
**Estimate vs Budget:** Within budget

---

## Deployment Execution Plan

Since automated deployment is blocked by AWS credentials, please follow these steps from your local machine or CI/CD runner:

### Deployment Commands

```bash
# 1. Authenticate with AWS (e.g. using aws sso or access keys)
aws sso login --profile <your-profile>
export AWS_PROFILE=<your-profile>

# 2. Navigate to the environment root
cd terraform/services/docs-portal/dev

# 3. Initialize Terraform
terraform init

# 4. Generate and review plan
terraform plan -out=tfplan
terraform show tfplan

# 5. Apply the changes
terraform apply tfplan
```

### Post-Deployment Verification

```bash
# Verify the generated URLs
terraform output

# Verify application health
curl -f https://kiranbakale.online/
```

---

## Sign-Off

```
Deployment Readiness Sign-Off

Service:      docs-portal
Environment:  dev
Date:         2026-08-04
Applied by:   Pending (Requires AWS Authentication)

Pre-Flight:         [ ] Blocked on AWS Auth
Cost Review:        [x] Approved
Security Review:    [x] Passed
Environment Gate:   [x] Passed
Rollback Plan:      [x] Documented
Documentation:      [x] Complete
```
