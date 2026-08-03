# Terraform SDD Workflow Guide

> **Skill:** `terraform-sdd`  
> **Skill location:** `.agents/skills/terraform-sdd/SKILL.md`

---

## Overview

The Terraform SDD workflow is a six-phase, gated process that transforms an infrastructure requirement into a production-grade, validated, security-reviewed Terraform deployment.

```
Engineer describes workload
         │
         ▼
    ┌─────────┐
    │  /spec  │  Ask infrastructure questions → infrastructure-spec.yaml
    └────┬────┘
         │ Gate: spec reviewed and approved
         ▼
    ┌─────────┐
    │  /plan  │  Architecture + module design → terraform-plan.md
    └────┬────┘
         │ Gate: plan reviewed and approved
         ▼
    ┌─────────┐
    │ /build  │  Generate Terraform → modules + service roots
    └────┬────┘
         │ Gate: fmt passes, no hardcoded values
         ▼
    ┌─────────┐
    │  /test  │  fmt + validate + tflint + terraform test
    └────┬────┘
         │ Gate: all validation passes
         ▼
    ┌──────────┐
    │ /review  │  Security scan + cost estimate
    └────┬─────┘
         │ Gate: no unresolved HIGH/CRITICAL findings
         ▼
    ┌─────────┐
    │  /ship  │  Deployment readiness → terraform apply
    └─────────┘
```

**Every gate is a hard stop.** No phase may begin before the previous one's gate is cleared.

---

## Phase Reference

### Phase 1: /spec

**Goal:** Produce a complete, approved `infrastructure-spec.yaml` and initial `architecture.md`.

**Inputs:** Vague requirement ("deploy my API service to the cloud")

**Process:**
1. Agent conducts structured discovery interview (9 question groups)
2. Surfaces missing information and asks until all REQUIRED fields are answered
3. Generates `infrastructure-spec.yaml` from `templates/infrastructure-spec.yaml`
4. Generates `architecture.md` from `templates/architecture.md`
5. Creates initial ADRs for any immediately-resolved decisions

**Outputs:**
```
specs/<service>/<env>/
  infrastructure-spec.yaml   ← Completed spec
  architecture.md            ← System design
  decisions/
    ADR-001-<title>.md       ← First decisions
```

**Gate:** Engineer reviews and explicitly approves the spec.

---

### Phase 2: /plan

**Goal:** Produce an approved `terraform-plan.md` with the complete module inventory, resource list, variable contract, and implementation order.

**Inputs:** Approved `infrastructure-spec.yaml` and `architecture.md`

**Process:**
1. Map workload to cloud primitives (using `references/workload-taxonomy.md`)
2. Identify which modules from `terraform/modules/` are needed
3. Design the module dependency graph
4. List every resource to be created
5. Define variable and output contracts
6. Design backend configuration
7. Identify risks and mitigations

**Outputs:**
```
plans/<service>/<env>/
  terraform-plan.md          ← Complete implementation plan
```

**Gate:** Engineer reviews and explicitly approves the plan. No Terraform code written yet.

---

### Phase 3: /build

**Goal:** Generate valid, well-structured Terraform code that passes `fmt` and has no hardcoded values.

**Inputs:** Approved `terraform-plan.md`

**Process:**
1. Create modules in dependency order (foundations first)
2. Create service root files
3. Run `terraform fmt -recursive` at each step
4. Verify no hardcoded values
5. Verify all variables have types and descriptions

**Outputs:**
```
terraform/
  modules/
    networking/
      main.tf, variables.tf, outputs.tf, versions.tf, README.md
    compute/
      main.tf, variables.tf, outputs.tf, versions.tf, README.md
    ...
  services/
    <service>/<env>/
      main.tf, variables.tf, outputs.tf, providers.tf,
      backend.tf, locals.tf, terraform.tfvars
```

**Gate:** `terraform fmt -check` passes. No hardcoded values.

---

### Phase 4: /test

**Goal:** All automated validations pass.

**Inputs:** Generated Terraform code from /build

**Commands (in order):**
```bash
# 1. Format check
terraform fmt -recursive -check

# 2. Init (no backend)
terraform init -backend=false

# 3. Validate
terraform validate

# 4. Lint
tflint --recursive --config .tflint.hcl

# 5. Unit tests (if .tftest.hcl files present)
terraform test
```

**Outputs:**
```
validation/
  terraform-report.md        ← Results of all validation steps
```

**Gate:** All commands exit 0. Any warnings are documented.

---

### Phase 5: /review

**Goal:** Zero unresolved HIGH or CRITICAL security findings. Cost within budget.

**Inputs:** Validated Terraform from /test

**Commands:**
```bash
# Security
checkov -d . --framework terraform
tfsec .

# Cost
infracost breakdown --path terraform/services/<service>/<env>
```

**Outputs:**
```
validation/
  security-report.md         ← Findings and documented exceptions
  cost-report.md             ← Infracost estimate
```

**Gate:** Zero unresolved HIGH/CRITICAL security findings. Cost estimate reviewed and within budget.

---

### Phase 6: /ship

**Goal:** Deployment readiness confirmed. `terraform apply` can run.

**Inputs:** Approved security and cost review

**Process:**
1. Complete `deployment-readiness.md` checklist
2. Run `terraform plan` and review output
3. Deploy to dev → verify → promote to staging → verify → promote to prod
4. Verify post-deployment (outputs, health checks, logs, metrics)

**Outputs:**
```
specs/<service>/<env>/
  deployment-readiness.md    ← Signed-off checklist

plans/<service>/<env>/
  terraform-plan-output.txt  ← Saved plan output
```

**Gate:** All items in `deployment-readiness.md` checked. Sign-off obtained.

---

## Repository Layout

```
spec-driven-terraform/
│
├── .agents/                         ← Agent skills and workspace rules
│   ├── AGENTS.md                    ← Workspace conventions and boundaries
│   └── skills/
│       └── terraform-sdd/
│           ├── SKILL.md             ← Core skill (6-phase lifecycle)
│           └── references/
│               ├── workload-taxonomy.md
│               ├── terraform-standards.md
│               ├── security-checks.md
│               └── definition-of-done.md
│
├── terraform/
│   ├── services/                    ← Per-service, per-environment roots
│   │   └── <service>/
│   │       └── <env>/
│   │           ├── main.tf
│   │           ├── variables.tf
│   │           ├── outputs.tf
│   │           ├── providers.tf
│   │           ├── backend.tf
│   │           ├── locals.tf
│   │           └── terraform.tfvars
│   └── modules/                     ← Reusable capability modules
│       ├── networking/
│       ├── compute/
│       ├── database/
│       ├── storage/
│       ├── iam/
│       └── monitoring/
│
├── specs/                           ← Infrastructure specs and architecture
│   └── <service>/
│       └── <env>/
│           ├── infrastructure-spec.yaml
│           ├── architecture.md
│           └── decisions/
│               └── ADR-NNN-<title>.md
│
├── plans/                           ← Terraform plans (markdown + output)
│   └── <service>/
│       └── <env>/
│           ├── terraform-plan.md
│           └── terraform-plan-output.txt
│
├── validation/                      ← Validation and scan reports
│   ├── terraform-report.md
│   ├── security-report.md
│   └── cost-report.md
│
├── templates/                       ← Document templates for each phase
│   ├── infrastructure-spec.yaml
│   ├── architecture.md
│   ├── ADR-000-template.md
│   ├── terraform-plan.md
│   └── deployment-readiness.md
│
└── docs/                            ← This documentation
    ├── workflow.md                  ← This file
    └── skill-usage.md              ← How to use the skill
```

---

## CI/CD Integration

### Pipeline Design

The workflow assumes these CI/CD pipelines exist:

#### PR Pipeline (runs on every Pull Request)

```
PR opened / updated
        │
        ▼
terraform fmt -check         ← Fails if code not formatted
        │
        ▼
terraform validate           ← Fails if syntax/logic errors
        │
        ▼
tflint                       ← Fails on lint errors
        │
        ▼
checkov / tfsec              ← Fails on HIGH/CRITICAL security findings
        │
        ▼
terraform plan               ← Shows what will change; saved as PR comment
        │
        ▼
infracost comment            ← Cost diff posted to PR
        │
        ▼
Required reviews             ← At least one approval required
```

#### Apply Pipeline (runs after PR merge to main / on manual trigger)

```
Merge to main
        │
        ▼
terraform plan               ← Generates final plan
        │
        ▼
Manual approval gate         ← Human reviews plan before apply
        │
        ▼
terraform apply              ← Apply with the approved plan file
        │
        ▼
Post-apply verification      ← Health checks, output validation
```

### Workspace Strategy

Use Terraform workspaces or separate state files per environment. **Recommended: separate state files** (clearer isolation):

```
services/<service>/dev/terraform.tfstate
services/<service>/staging/terraform.tfstate
services/<service>/prod/terraform.tfstate
```

---

## Decision Logging Protocol

Every significant infrastructure decision gets an ADR:

### Mandatory ADR Topics

| Topic | When to Write |
|-------|--------------|
| Cloud provider selection | At /spec |
| Network design | At /plan |
| Compute service selection | At /plan |
| Database engine choice | At /plan |
| IAM model | At /plan |
| Secret management strategy | At /plan |
| State backend | Before /build |
| HA / multi-AZ decision | At /plan |
| Cost optimization decisions | At /plan or /review |

### ADR Lifecycle

```
Proposed → Accepted → Superseded (write new ADR) → Deprecated
```

Never delete old ADRs. They preserve historical context.

---

## Common Workflow Scenarios

### Scenario 1: New Service, New Environment

```
/spec    → Full discovery interview → new infrastructure-spec.yaml
/plan    → New architecture + ADRs + new terraform-plan.md
/build   → Create all modules (if not existing) + service root
/test    → Validate everything
/review  → Security + cost
/ship    → dev → staging → prod
```

### Scenario 2: New Environment for Existing Service

```
/spec    → Abbreviated spec (reuse existing workload definition, specify env differences)
/plan    → No new modules needed; just new tfvars + backend config
/build   → Copy service root, update tfvars for new env
/test    → Validate
/review  → Security + cost for new env
/ship    → Deploy new env
```

### Scenario 3: Adding a Module to an Existing Service

```
/spec    → Update infrastructure-spec.yaml with new requirement
/plan    → Add new module to plan; update variable/output contracts
/build   → Create or update module; update service root
/test    → Validate changes
/review  → Security re-scan; cost diff
/ship    → Plan shows only new resource additions; apply
```
