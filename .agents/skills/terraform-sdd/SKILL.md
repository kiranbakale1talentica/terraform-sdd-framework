---
name: terraform-sdd
description: >
  MANDATORY driver for all cloud infrastructure work in this repository.
  Triggers on /spec, /plan, /build, /test, /review, /ship, /tf-spec, /tf-build,
  "create infrastructure", "provision", "terraform", "deploy to cloud", "infrastructure spec".
  Overrides generic application spec-driven-development.
---

# Terraform Specification Driven Development (SDD)

## Overview

Infrastructure without a specification is guessing. This skill enforces a **six-phase gated workflow** that transforms a vague infrastructure requirement into production-grade, validated, security-reviewed Terraform — with every decision documented along the way.

The workflow mirrors the software spec-driven approach but is purpose-built for **cloud infrastructure only**: Terraform, cloud provisioning, and infrastructure automation.

```
New Project / Account
     │
     ▼
/bootstrap ─ AWS OIDC & State Storage Bootstrap
     │           (runs templates/bootstrap-aws.tf -> S3 state bucket + OIDC IAM Role)
     ▼
/spec ────── Infrastructure Specification
     │           (infrastructure-spec.yaml + architecture.md + ADRs)
     ▼
/plan ────── Architecture + Terraform Plan
     │           (terraform-plan.md + module dependency graph)
     ▼
/build ───── Terraform Generation
     │           (main.tf, variables.tf, outputs.tf, modules)
     ▼
/test ────── Validation
     │           (fmt + validate + tflint + terraform test)
     ▼
/review ──── Security + Quality Review
     │           (Checkov + tfsec + cost estimate)
     ▼
/ship ────── Deployment Readiness
                 (deployment-readiness.md signed off)
```

**No phase may be skipped. No gate may be soft-bypassed.**

---

## Phase 0: /bootstrap — AWS State & OIDC Identity Setup

When `/bootstrap` is triggered or when starting in a new AWS account:

1. **Step 1: Authenticate & Confirm Credentials:**
   Ask the user to ensure their local AWS CLI profile is authenticated with an IAM Identity (User or Role) that has permissions to create IAM Roles (`iam:CreateRole`, `iam:PutRolePolicy`, `iam:CreateOpenIDConnectProvider`) and S3 Buckets (`s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutEncryptionConfiguration`).
   *Ask the user for their exact AWS Profile name (e.g. `export AWS_PROFILE=my-aws-profile`).*

2. **Step 2: Explain Purpose & CI/CD Mechanics:**
   Explain to the user **WHY** we are running bootstrap:
   - *"We are creating a dedicated **S3 Remote State Bucket** to safely lock and store Terraform state files."*
   - *"We are creating a **GitHub Actions OIDC IAM Role** so GitHub Actions CI/CD pipelines can authenticate to AWS keylessly (without long-lived secret keys) to provision resources on your behalf."*

3. **Step 3: Confirm Resource Names & Parameters:**
   Confirm the target resource names and MANDATORY OIDC claims with the user before applying:
   - **S3 State Bucket Name:** `terraform-sdd-tfstate-<aws-account-id>`
   - **GitHub Actions IAM Role Name:** `<project-prefix>-actions-role` (e.g. `terraform-sdd-actions-role`)
   - **GitHub Repository Identifier:** `<github-org>/<github-repo>`
   - **REQUIRED OIDC Subject Claim Prefix:** Prompt the user:
     > *"Please go to **GitHub Repo Settings > Actions > General > OpenID Connect subject claim**, copy your repository's exact custom subject claim template string (e.g. `repo:org@id/repo@id`), and provide it here. This parameter is REQUIRED."*

4. **Step 4: Execute Bootstrap & Output Secret:**
   Execute `templates/bootstrap-aws.tf` passing `-var="github_org_repo=..."` and `-var="github_oidc_sub_claim=..."` using the user's confirmed AWS profile.

5. **Gate Rule (STOP & WAIT):** Output the generated `s3_bucket_name` and `github_actions_role_arn`. Instruct the user to save `AWS_ROLE_ARN` in GitHub Repo Secrets before moving to Phase 1 (`/spec`).

---

## ⛔ Gated Phase Execution Rules (CRITICAL)

The agent MUST enforce a strict **STOP & WAIT** behavior between every phase:

1. **ONE PHASE PER TURN:** The agent MUST NOT execute more than ONE phase per turn under any circumstances.
2. **EXPLICIT HUMAN APPROVAL:** At the end of every phase, the agent MUST output the generated artifact links and explicitly ask:
   > *"Phase [N] complete. Please review the generated artifacts above. Reply with approval or next command to proceed to Phase [N+1]."*
3. **STRICT BLOCKING:** Do NOT generate `.tf` code during `/spec` or `/plan`. Do NOT run security scans during `/build`. Follow the 6-phase sequence strictly step-by-step.

---

## When to Use

- An engineer says "create infrastructure for X"
- A requirement mentions cloud resources, provisioning, networking, compute, databases, storage
- Any Terraform needs to be written, modified, or reviewed
- An existing infrastructure spec needs to be updated
- A new environment (dev, staging, prod) needs to be provisioned

**When NOT to use:** Application code, frontend components, backend services, CI/CD for application deployments (only for infrastructure deployments). Redirect to `spec-driven-development` for application work.

---

## Phase 1: /spec — Infrastructure Specification

### Discovery Interview

Before writing a single line of Terraform, conduct a structured discovery interview. **Never skip questions.** Missing answers mean missing infrastructure.

Run through the following question groups. Ask all questions in a group before moving to the next.

#### Group 1 — Workload Identity

```
What type of workload is being deployed?

  A) Containerized service (Docker, stateless HTTP)
  B) Kubernetes workload (pods, deployments, services)
  C) Serverless workload (functions, event-driven)
  D) VM-based workload (traditional compute)
  E) Data pipeline / batch processing
  F) Frontend hosting (static site, SPA, CDN)
  G) Backend API (REST, GraphQL, gRPC)
  H) AI/ML workload (training, inference, notebooks)
  I) Database / data store
  J) Message queue / event streaming
  K) Other (describe)

How many instances/replicas are expected at peak?
What is the expected request volume or throughput?
Are there any latency SLAs?
```

#### Group 2 — Cloud Provider

```
Which cloud provider?

  A) AWS
  B) Azure
  C) GCP
  D) Multi-cloud (specify which)
  E) Provider neutral (select based on requirements)

If provider-neutral: do you have existing agreements, credits, or team expertise
that should influence provider selection?
```

#### Group 3 — Environment Strategy

```
Which environments are needed?

  A) dev only
  B) dev + staging + prod
  C) dev + test + staging + prod
  D) Custom (specify)

Should each environment be isolated (separate VPCs/VNets/projects)?
Should environments share any infrastructure (e.g., shared services VPC)?
What is the promotion strategy (how does code move from dev → prod)?
```

#### Group 4 — Networking

```
Networking requirements:

- Public internet access required? (yes/no/load-balancer-only)
- Private networking required? (VPC/VNet/subnet design)
- Cross-service communication: same VPC? service mesh? API gateway?
- DNS requirements? (custom domains, private DNS zones)
- CDN requirements?
- VPN or private connectivity to on-premises?
- Network segmentation requirements? (public/private/data subnets)
- Firewall/WAF requirements?
- DDoS protection?
```

#### Group 5 — Security

```
Security requirements:

- Identity and access: IAM roles needed? service accounts? OIDC?
- Secrets management: where are secrets stored? (Vault, Secrets Manager, Key Vault)
- Encryption at rest: required? key management requirements?
- Encryption in transit: TLS termination? mTLS?
- Compliance frameworks: PCI-DSS? SOC2? HIPAA? ISO27001? GDPR?
- Vulnerability scanning on container images?
- Network policies / security groups: default-deny or open?
- Audit logging: cloud trail/audit log requirements?
```

#### Group 6 — Scaling and Availability

```
Scaling requirements:

- Auto-scaling: horizontal? vertical? scheduled?
- Minimum and maximum instance counts?
- Scaling triggers: CPU? memory? request rate? custom metric?

Availability requirements:

- Target uptime SLA? (99%, 99.9%, 99.99%)
- Multi-AZ deployment required?
- Multi-region required?
- Active-active or active-passive HA?
```

#### Group 7 — Reliability

```
Disaster recovery:

- RTO (Recovery Time Objective)?
- RPO (Recovery Point Objective)?
- Backup frequency and retention?
- Cross-region backup required?
- Runbook / DR playbook required?
```

#### Group 8 — Observability

```
Monitoring and logging:

- Metrics: which platform? (CloudWatch, Azure Monitor, Cloud Monitoring, Datadog, Prometheus)
- Logging: centralized log aggregation? (CloudWatch Logs, Log Analytics, Cloud Logging, Splunk, ELK)
- Tracing: distributed tracing required? (X-Ray, Jaeger, Cloud Trace)
- Alerting: PagerDuty? Opsgenie? Slack? email?
- Dashboards: required? which tool?
- Health checks and uptime monitoring?
```

#### Group 9 — Cost and Compliance

```
Cost requirements:

- Monthly budget target?
- Cost allocation tags required?
- Reserved instances or committed use discounts?
- Spot/preemptible instances acceptable for any workloads?
- Cost anomaly alerts?

Compliance / data residency:

- Data must stay in specific regions?
- Data classification level? (public, internal, confidential, restricted)
- Retention policies for logs and backups?
```

### Missing Information Gate

**Do NOT proceed to /plan if ANY of the following are unknown:**

- [ ] Workload type is not identified
- [ ] Cloud provider is not confirmed
- [ ] Target environment(s) are not defined
- [ ] Security model (IAM, secrets, encryption) is not specified
- [ ] Networking isolation requirements are unclear

Surface the gap explicitly:

```
MISSING INFORMATION — cannot proceed to /plan:

The following are not yet specified:
1. [missing item]
2. [missing item]

Please answer these before we continue.
```

### Spec Output

Once all discovery questions are answered, produce:

1. **`specs/<service>/<env>/infrastructure-spec.yaml`** — using `templates/infrastructure-spec.yaml`
2. **`specs/<service>/<env>/architecture.md`** — using `templates/architecture.md`
3. First ADRs for any significant provider or design decisions — using `templates/ADR-000-template.md`

Store ADRs at: `specs/<service>/<env>/decisions/ADR-NNN-<short-title>.md`

---

## Phase 2: /plan — Architecture + Terraform Plan

Entry: Approved `infrastructure-spec.yaml` and `architecture.md`.

### Planning Steps

1. **Map workload to cloud primitives** — use `references/workload-taxonomy.md`
2. **Identify required modules** — which capabilities from `terraform/modules/` are needed?
3. **Design the module dependency graph** — what depends on what?
4. **Define the resource list** — every resource that will be created
5. **Design variable and output contracts** — what goes in, what comes out
6. **Plan remote state** — backend config and state file organization
7. **Identify risks** — what could fail? what are the mitigations?

### Plan Output

Produce `plans/<service>/<env>/terraform-plan.md` using `templates/terraform-plan.md`.

The plan must include:
- Module list with purpose
- Resource inventory table
- Variable contract (name, type, description, required/optional)
- Backend configuration design
- Implementation order (dependency-first)
- Verification checkpoints

**Do NOT write Terraform files during /plan.** Output is the plan document only.

---

## Phase 3: /build — Terraform Generation

Entry: Approved `terraform-plan.md`.

### Generation Rules

1. **Start with modules first** — build `terraform/modules/` before service roots
2. **Follow the canonical file layout** (see AGENTS.md)
3. **Every variable must have a description and type**
4. **Every output must have a description**
5. **Use locals for naming and tagging** — never repeat the same string twice
6. **Backend must be configurable** — use partial backend configuration
7. **No hardcoded values** — every environment-specific value is a variable or tfvar

### Terraform File Structure

Every service root (`terraform/services/<service>/<env>/`) must contain:

```hcl
# providers.tf
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    # provider blocks
  }
}

# backend.tf
terraform {
  backend "s3" {}  # or "azurerm", "gcs" — configured via -backend-config
}

# locals.tf
locals {
  name_prefix  = "${var.project}-${var.environment}"
  common_tags  = { ... }
}

# main.tf
# Module calls only — no resources directly in root
module "networking" {
  source = "../../../modules/networking"
  # ...
}

# variables.tf
variable "project" {
  type        = string
  description = "Project name used in resource naming and tagging"
}

# outputs.tf
output "vpc_id" {
  value       = module.networking.vpc_id
  description = "ID of the created VPC"
}

# terraform.tfvars
project     = "myproject"
environment = "dev"
```

### Module Design Principles

Modules must represent **capabilities**, not services or providers:

| Good | Bad |
|------|-----|
| `modules/networking` | `modules/aws-api-service-prod` |
| `modules/compute` | `modules/frontend-s3-cloudfront` |
| `modules/iam` | `modules/dev-database-module` |

Each module must be:
- Usable across multiple services
- Usable across environments (dev, staging, prod) via variables
- Usable across providers where practical (abstract the provider-specific detail inside)

### Build Gate

Before exiting /build:
- [ ] All `.tf` files exist per canonical layout
- [ ] `terraform fmt -check` passes (zero diff)
- [ ] No hardcoded region, account IDs, IP addresses, passwords
- [ ] All variables have `type` and `description`
- [ ] All outputs have `description`

---

## Phase 4: /test — Validation

Entry: Build gate passed.

### Validation Sequence

Run in this order. Stop and fix before proceeding if any step fails.

```bash
# Step 1: Format check
terraform fmt -recursive -check

# Step 2: Initialize (no real backend)
terraform init -backend=false

# Step 3: Validate
terraform validate

# Step 4: Lint
tflint --recursive --config .tflint.hcl

# Step 5: Unit tests (if .tftest.hcl files exist)
terraform test
```

### Writing Terraform Unit Tests

For modules that accept inputs and produce outputs, write `.tftest.hcl` files:

```hcl
# terraform/modules/networking/tests/basic.tftest.hcl

variables {
  project     = "test"
  environment = "unit"
  cidr_block  = "10.0.0.0/16"
}

run "creates_vpc_with_correct_cidr" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should match input variable"
  }
}
```

### Test Gate

- [ ] `fmt` — zero diff
- [ ] `validate` — exit code 0
- [ ] `tflint` — zero errors (warnings documented if accepted)
- [ ] `terraform test` — all tests pass (if tests exist)
- [ ] Output: `validation/terraform-report.md` written

---

## Phase 5: /review — Security + Quality Review

Entry: /test gate passed.

### Security Scan

```bash
# Checkov
checkov -d . --framework terraform --output json > validation/checkov-report.json
checkov -d . --framework terraform --output cli

# tfsec
tfsec . --format json > validation/tfsec-report.json
tfsec . --format text
```

### Security Review Checklist

See `references/security-checks.md` for the full checklist. Summary:

- [ ] No resources are publicly exposed unless explicitly required and documented
- [ ] All storage (S3, blob, GCS) has public access blocked
- [ ] All databases are not publicly accessible
- [ ] Encryption at rest is enabled for all data stores
- [ ] Encryption in transit (TLS) is enforced
- [ ] IAM policies follow least-privilege principle
- [ ] Security groups / NSGs use specific ports, not 0-65535
- [ ] Secrets are not in Terraform variables or tfvars (use secrets manager references)
- [ ] Logging is enabled on all critical resources
- [ ] No `*` in IAM resource ARNs unless justified and documented

### Cost Estimate

```bash
infracost breakdown --path terraform/services/<service>/<env> \
  --format json > validation/cost-estimate.json
infracost output --path validation/cost-estimate.json --format table
```

### Review Gate

- [ ] Checkov: zero HIGH or CRITICAL findings (or all findings have documented exceptions)
- [ ] tfsec: zero HIGH findings (or all findings have documented exceptions)
- [ ] Cost estimate reviewed and within budget
- [ ] Security exceptions documented with justification
- [ ] Output: `validation/security-report.md` written

---

## Phase 6: /ship — Deployment Readiness

Entry: /review gate passed.

### Deployment Readiness Checklist

Use `templates/deployment-readiness.md`. The checklist covers:

**Pre-flight:**
- [ ] All validation gates passed (fmt, validate, lint, test)
- [ ] Security review complete (no unresolved HIGH/CRITICAL)
- [ ] Cost estimate reviewed and approved
- [ ] Remote state backend configured and accessible
- [ ] All required secrets exist in secrets manager (not in code)
- [ ] `terraform plan` run against target environment — output reviewed
- [ ] Plan output saved to `plans/<service>/<env>/terraform-plan-output.txt`

**Deployment Order:**
- [ ] Environments promoted in order: dev → staging → prod
- [ ] Each environment deployed and verified before promoting to next
- [ ] Rollback plan documented
- [ ] `terraform destroy` tested in dev (if new infrastructure pattern)

**Post-deployment:**
- [ ] Outputs verified (IDs, ARNs, endpoints)
- [ ] Health checks passing
- [ ] Monitoring and alerting configured
- [ ] ADRs final and committed
- [ ] README updated for the service

### CI/CD Integration

The `/ship` phase assumes CI/CD pipelines exist for:
- **PRs:** `terraform fmt` + `terraform validate` + `tflint` + `terraform plan`
- **Merges:** `terraform apply` with approval gate

See `docs/workflow.md` for CI/CD pipeline reference.

---

## Workload → Provider Mapping

See `references/workload-taxonomy.md` for the full mapping.

Quick reference:

| Workload | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Container service | ECS Fargate | Container Apps | Cloud Run |
| Kubernetes | EKS | AKS | GKE |
| Serverless | Lambda | Functions | Cloud Functions |
| VM | EC2 | VM | Compute Engine |
| Data pipeline | Glue + Step Functions | Data Factory | Dataflow |
| Frontend hosting | S3 + CloudFront | Static Web Apps | Cloud Storage + LB |
| Backend API | API Gateway + Lambda / ECS | API Management | API Gateway + Cloud Run |
| AI/ML | SageMaker | Azure ML | Vertex AI |

---

## Decision Logging

Every significant infrastructure decision requires an ADR.

Mandatory ADRs:
- Cloud provider selection
- Network design (VPC/VNet topology, CIDR ranges)
- Compute selection (why this service type for this workload)
- Database engine and service selection
- IAM / identity model
- Secret management strategy
- State backend selection
- Multi-region or multi-AZ strategy

Use `templates/ADR-000-template.md`. Store at `specs/<service>/<env>/decisions/`.

---

## Keeping the Spec Alive

The `infrastructure-spec.yaml` is a living document:
- Update it when requirements change — before changing Terraform
- Update ADRs when decisions are superseded — write a new ADR, don't delete the old one
- Commit specs alongside Terraform code — they belong in version control together
- Reference spec sections in PRs — link the spec section a PR implements

---

## Common Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Hardcoded region/account in `.tf` files | Variable with default, or backend config |
| Resources directly in root module | Call modules from root; put resources in modules |
| One giant `main.tf` file | Split by concern: networking, compute, iam, monitoring |
| Provider-specific module names | Capability names: `networking`, not `aws-vpc-module` |
| Secrets in `terraform.tfvars` | Reference secrets manager ARN/ID; inject at runtime |
| Skipping `/spec` for "simple" changes | Simple changes also need spec acceptance criteria |
| Copy-paste environments | Same module, different tfvars |

---

## Red Flags

- Generating Terraform when workload type or cloud provider is unknown
- No ADR for the cloud provider decision
- `terraform.tfvars` containing passwords or tokens
- A module named after a specific service rather than a capability
- No outputs from a module (how does the parent know what was created?)
- No backend configuration (local state is not production-ready)
- Skipping the security scan before `/ship`

---

## See Also

- `references/workload-taxonomy.md` — workload to cloud service mapping
- `references/terraform-standards.md` — detailed Terraform coding standards
- `references/security-checks.md` — security review checklist
- `references/definition-of-done.md` — standing bar for every /ship
- `templates/` — document templates for each phase
- `docs/workflow.md` — end-to-end workflow guide
- `docs/skill-usage.md` — how to invoke this skill
