# Definition of Done — Terraform SDD

> **Used by:** `/ship` phase of the Terraform SDD skill  
> **Purpose:** The standing bar every infrastructure change must clear before it is considered done

---

## Overview

"Done" is not "Terraform apply succeeded." Done means the infrastructure is:
- Formatted, validated, and linted
- Tested (unit + integration where applicable)
- Security-reviewed with no unresolved critical findings
- Cost-estimated and within budget
- Documented with ADRs and updated README
- Deployed through the proper environment gates
- Observable (monitoring and alerts configured)
- Reversible (rollback plan exists)

If any item below is unchecked, the work is **not done**.

---

## Code Quality Gate

- [ ] `terraform fmt -recursive -check` exits with code 0 (zero diff)
- [ ] `terraform validate` exits with code 0 in all service roots
- [ ] `tflint --recursive` exits with zero errors (warnings documented if accepted)
- [ ] All `.tf` files follow the canonical file layout (see `references/terraform-standards.md`)
- [ ] No resources defined directly in root module (all in modules)
- [ ] All variables have `type` and `description`
- [ ] All outputs have `description`
- [ ] No hardcoded values: no region, account ID, IP addresses, passwords, or tokens
- [ ] Locals used for all repeated string patterns (name prefix, common tags)
- [ ] Provider version constraints use pessimistic operator (`~>`)
- [ ] `required_version` constraint is set for Terraform itself

---

## Testing Gate

- [ ] `terraform test` passes (if `.tftest.hcl` files exist for any module)
- [ ] Module unit tests cover the primary happy path
- [ ] Module unit tests cover at least one failure/edge case (if applicable)
- [ ] `terraform plan` has been run and reviewed (no unexpected resource changes)
- [ ] Terraform plan output is saved to `plans/<service>/<env>/terraform-plan-output.txt`

---

## Security Gate

- [ ] Checkov scan completed — zero unresolved HIGH or CRITICAL findings
- [ ] tfsec scan completed — zero unresolved HIGH findings
- [ ] All security exceptions documented in `validation/security-report.md` with justification
- [ ] No secrets in `.tf` files, `.tfvars` files, or Terraform state (where avoidable)
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] IAM roles/policies reviewed for least-privilege
- [ ] Network exposure matches the specification (no unexpected public resources)
- [ ] Encryption at rest confirmed for all data stores
- [ ] Encryption in transit confirmed for all external-facing services

---

## Cost Gate

- [ ] `infracost breakdown` has been run and output is in `validation/cost-report.md`
- [ ] Monthly cost estimate is within the budget stated in the spec
- [ ] Cost allocation tags are applied to all resources
- [ ] Cost anomaly alerts are configured
- [ ] Reserved instances or committed use decisions are documented if relevant

---

## Documentation Gate

- [ ] `infrastructure-spec.yaml` is final and matches what was built
- [ ] `architecture.md` accurately reflects the deployed architecture
- [ ] All significant decisions have ADRs:
  - [ ] Cloud provider selection (if not already existing)
  - [ ] Network design
  - [ ] Compute selection
  - [ ] Database/storage selection
  - [ ] IAM/identity model
  - [ ] Secret management strategy
  - [ ] State backend selection
- [ ] Module `README.md` files are written for any new or modified modules
- [ ] Service root `README.md` exists with: what it provisions, how to init/plan/apply, backend config instructions

---

## State Management Gate

- [ ] Remote backend is configured (not local state)
- [ ] State locking is enabled
- [ ] State file is stored in the correct path: `services/<service>/<env>/terraform.tfstate`
- [ ] State file is not committed to version control (`.gitignore` covers `*.tfstate`)
- [ ] Backend config file exists: `backends/<env>.tfbackend` (not committed if it contains sensitive values)
- [ ] State access is restricted to authorized CI/CD roles and engineers

---

## Deployment Gate

- [ ] dev environment deployed and verified
- [ ] staging environment deployed and verified (for production-bound changes)
- [ ] `terraform apply` output reviewed — no unexpected resource counts
- [ ] Post-apply outputs verified (VPC IDs, endpoint URLs, ARNs match expected)
- [ ] Application health checks pass after infrastructure deployment

---

## Observability Gate

- [ ] CloudWatch / Azure Monitor / Cloud Monitoring metrics are flowing
- [ ] Log groups / Log Analytics workspaces are created and receiving logs
- [ ] Alerting rules are configured for:
  - [ ] High error rate
  - [ ] High CPU/memory
  - [ ] Disk space (for VM workloads)
  - [ ] Database connection pool saturation
  - [ ] Cost anomaly
- [ ] Dashboard exists (or is linked) for the service
- [ ] Health check endpoint is reachable and returning 200

---

## Rollback Gate

- [ ] Rollback plan is documented in `templates/deployment-readiness.md`
- [ ] `terraform destroy` tested in dev (for new infrastructure patterns)
- [ ] Previous state is backed up before production apply
- [ ] Runbook exists for emergency rollback procedure

---

## Version Control Gate

- [ ] All Terraform files are committed to version control
- [ ] Spec files (`infrastructure-spec.yaml`, `architecture.md`, ADRs) are committed alongside code
- [ ] PR references the spec section it implements
- [ ] Commit message follows conventional commit format
- [ ] No `.terraform/` directories, `*.tfstate` files, or `*.tfstate.backup` files are committed
- [ ] `.gitignore` covers all Terraform-generated files

---

## Sign-Off

Before marking work complete, confirm:

```
Infrastructure change sign-off:

Service:      <service-name>
Environment:  <env>
Date:         <YYYY-MM-DD>

[ ] Code Quality Gate — passed
[ ] Testing Gate — passed
[ ] Security Gate — passed
[ ] Cost Gate — passed
[ ] Documentation Gate — passed
[ ] State Management Gate — passed
[ ] Deployment Gate — passed
[ ] Observability Gate — passed
[ ] Rollback Gate — passed
[ ] Version Control Gate — passed

Signed: <author>
```
