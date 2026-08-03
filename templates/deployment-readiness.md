# Deployment Readiness: [Service Name] — [Environment]

<!--
Usage: Copy this file to specs/<service>/<env>/deployment-readiness.md
Complete every section before /ship is approved.
This document must be signed off before Terraform apply runs against production.
-->

> **Service:** [service-name]  
> **Environment:** [env]  
> **Terraform Plan:** [terraform-plan.md](../../plans/[service]/[env]/terraform-plan.md)  
> **Validation:** [terraform-report.md](../../validation/terraform-report.md)  
> **Security Report:** [security-report.md](../../validation/security-report.md)  
> **Date:** YYYY-MM-DD

---

## Pre-Flight Checklist

### Code Quality

- [ ] `terraform fmt -recursive -check` — exit code 0, zero diff
- [ ] `terraform validate` — exit code 0 in all roots and modules
- [ ] `tflint --recursive` — zero errors
- [ ] `terraform test` — all tests passing (if test files exist)
- [ ] All variables have `type` and `description`
- [ ] All outputs have `description`
- [ ] No hardcoded secrets, account IDs, IP addresses, or region names
- [ ] `terraform.tfvars` does not contain sensitive values

### Terraform Plan Review

- [ ] `terraform plan` has been run against target environment
- [ ] Plan output saved to `plans/[service]/[env]/terraform-plan-output.txt`
- [ ] Plan output reviewed — no unexpected resource additions, modifications, or destructions
- [ ] Resource count matches expected (see terraform-plan.md resource inventory)
- [ ] No resources with `forces replacement` unless intentional and approved
- [ ] Cost estimate reviewed (see Section: Cost)

### Security

- [ ] Checkov scan complete — zero unresolved HIGH or CRITICAL findings
- [ ] tfsec scan complete — zero unresolved HIGH findings
- [ ] All security exceptions documented in `validation/security-report.md`
- [ ] No resources with unexpected public internet access
- [ ] No secrets in Terraform state (or all sensitive are marked `sensitive = true`)
- [ ] IAM roles reviewed for least-privilege
- [ ] Network security groups reviewed — no 0.0.0.0/0 on management ports

### State Management

- [ ] Remote backend configured (not local state)
- [ ] State locking enabled (DynamoDB table / blob lease / GCS lock)
- [ ] State file path: `services/[service]/[env]/terraform.tfstate`
- [ ] Backend access verified (CI/CD role has sufficient permissions)
- [ ] Previous state backed up (for production changes)
- [ ] `.gitignore` covers `*.tfstate`, `*.tfstate.backup`, `.terraform/`

### Secrets and Credentials

- [ ] All required secrets exist in secrets manager before apply
- [ ] CI/CD credentials are scoped to minimum required permissions
- [ ] No plaintext credentials in environment variables or CI/CD variables
- [ ] Secret rotation is configured (if applicable)

---

## Cost Estimate

| Resource | Monthly Estimate (USD) | Notes |
|---------|----------------------|-------|
| Compute | | |
| Database | | |
| Networking (NAT, LB) | | |
| Storage | | |
| Monitoring / Logging | | |
| **Total Estimate** | | |

**Budget:** $[X] / month (from spec)  
**Estimate vs Budget:** Within budget / Over budget — [notes]

Cost report: [cost-report.md](../../validation/cost-report.md)

---

## Environment Gates

### dev → staging Promotion

- [ ] dev environment deployed successfully
- [ ] Application health check returning 200 in dev
- [ ] Integration tests passing in dev
- [ ] No open HIGH security findings from dev scan
- [ ] dev cost within expected range

### staging → prod Promotion

- [ ] staging environment deployed successfully
- [ ] Application health check returning 200 in staging
- [ ] Load testing / performance validation complete in staging
- [ ] Security team / architecture team sign-off obtained
- [ ] Change management ticket approved (if applicable)
- [ ] Deployment window scheduled

---

## Deployment Execution Plan

### Pre-Deployment Steps

1. Notify stakeholders of deployment window
2. Verify secrets exist in secrets manager:
   ```bash
   # Example: AWS
   aws secretsmanager list-secrets --query "SecretList[?starts_with(Name, '/[project]/[env]/')]"
   ```
3. Back up current state:
   ```bash
   terraform state pull > pre-deploy-state-backup-$(date +%Y%m%d-%H%M%S).tfstate
   ```

### Deployment Commands

```bash
# Initialize with environment backend
terraform init -backend-config=backends/[env].tfbackend

# Generate and review plan
terraform plan \
  -var-file=terraform.tfvars \
  -out=tfplan

# Review plan output
terraform show tfplan

# Apply (requires human review of plan output above)
terraform apply tfplan
```

### Post-Deployment Verification

```bash
# Verify outputs
terraform output

# Verify application health
curl -f https://[service-url]/health

# Verify logs are flowing
# AWS: aws logs tail /aws/ecs/[service] --follow
# Azure: az monitor log-analytics query ...
# GCP: gcloud logging read ...
```

---

## Rollback Plan

### Immediate Rollback (Terraform Destroy)

**When to use:** New infrastructure that has never been in production, or when the deployed state is catastrophically broken.

```bash
# Review what will be destroyed first
terraform plan -destroy -out=destroy-plan
terraform show destroy-plan

# Destroy only if approved
terraform apply destroy-plan
```

### Configuration Rollback (Previous Terraform Version)

**When to use:** Deployed configuration is wrong but resources are in use.

```bash
# Check state versions (if backend supports versioning)
# Restore previous .tf files from git

# Revert to previous commit
git checkout <previous-commit> -- terraform/services/[service]/[env]/

# Re-apply previous configuration
terraform plan -var-file=terraform.tfvars -out=rollback-plan
terraform apply rollback-plan
```

### Emergency Contacts

| Role | Contact | Escalation |
|------|---------|-----------|
| Infrastructure Lead | [name / Slack handle] | |
| Cloud Account Owner | [name / Slack handle] | |
| On-Call Engineer | [PagerDuty rotation] | |

---

## Observability Checklist

- [ ] CloudWatch / Azure Monitor / Cloud Monitoring metrics are flowing
- [ ] Log groups created and receiving application logs
- [ ] Alarms configured:
  - [ ] High error rate → PagerDuty / Slack
  - [ ] High latency → Slack
  - [ ] High CPU / memory → Slack
  - [ ] Cost anomaly → Email
- [ ] Dashboard accessible and showing data
- [ ] Health check / uptime monitoring configured (external)

---

## Documentation

- [ ] `infrastructure-spec.yaml` finalized and committed
- [ ] `architecture.md` accurate and committed
- [ ] All ADRs written and committed to `specs/[service]/[env]/decisions/`
- [ ] Module `README.md` files present for new modules
- [ ] Service root README exists with init/plan/apply instructions
- [ ] This deployment readiness checklist committed alongside the code

---

## Sign-Off

```
Deployment Readiness Sign-Off

Service:      [service-name]
Environment:  [environment]
Date:         YYYY-MM-DD
Applied by:   [name]

Pre-Flight:         [ ] Complete
Cost Review:        [ ] Approved
Security Review:    [ ] Passed
Environment Gate:   [ ] Passed
Rollback Plan:      [ ] Documented
Observability:      [ ] Configured
Documentation:      [ ] Complete

Approved by: [Name / Team]
Approval date: YYYY-MM-DD
```

---

## Post-Deployment Notes

<!-- Fill in after deployment -->

**Applied at:** YYYY-MM-DD HH:MM UTC  
**Applied by:** [name]  
**Resources created:** [X] added, [Y] changed, [Z] destroyed  
**Issues encountered:** [none / description]  
**Time to healthy:** [X] minutes  
**Follow-up items:**
- [ ] [item]
