# Terraform SDD Skill — Usage Guide

> **Skill:** `terraform-sdd`  
> **Workflow reference:** [workflow.md](./workflow.md)

---

## How the Skill is Invoked

The `terraform-sdd` skill is automatically discovered from `.agents/skills/terraform-sdd/SKILL.md`.

It activates when you describe an infrastructure need:

**Natural language triggers:**
- "Create infrastructure for my API service"
- "Provision a Kubernetes cluster on AWS"
- "Deploy a PostgreSQL database to Azure"
- "I need a data pipeline infrastructure on GCP"

**Slash command triggers:**
- `/spec` — Start the infrastructure specification phase
- `/plan` — Move to architecture and Terraform planning
- `/build` — Generate Terraform code
- `/test` — Run validation suite
- `/review` — Run security scan and cost estimate
- `/ship` — Complete deployment readiness checklist

---

## End-to-End Walkthrough

### Starting Point: "Create infrastructure for my application"

The agent will respond with the discovery interview. Here's an example session:

---

**Agent:** Let's start with `/spec`. I'll ask you questions across 9 areas to build a complete infrastructure specification. Missing answers block the next phase.

**Group 1 — Workload Type**

> What type of workload is being deployed?
> A) Containerized service (Docker, stateless HTTP)
> B) Kubernetes workload
> C) Serverless workload
> D) VM-based workload
> E) Data pipeline / batch processing
> F) Frontend hosting (static site, SPA, CDN)
> G) Backend API
> H) AI/ML workload
> I) Database / data store
> J) Message queue / event streaming

**Engineer:** G — Backend API. It's a REST API built with Node.js.

**Agent:** Got it. Continuing...

> How many instances/replicas at peak? Any latency SLAs?

**Engineer:** Up to 10 instances. Target p99 < 200ms.

**Agent:** Noted. Moving to cloud selection...

> Which cloud provider?
> A) AWS  B) Azure  C) GCP  D) Multi-cloud  E) Provider neutral

**Engineer:** AWS.

...and so on through all 9 groups.

---

After the interview, the agent:
1. Writes `specs/api-service/dev/infrastructure-spec.yaml`
2. Writes `specs/api-service/dev/architecture.md`
3. Writes any initial ADRs
4. Asks: "Please review the spec and architecture. Type 'approved' to proceed to /plan."

---

### /plan Phase

After spec approval, you say: `/plan`

The agent:
1. Maps the Node.js REST API on AWS to: **ALB + ECS Fargate + RDS Aurora + ElastiCache Redis**
2. Identifies required modules: `networking`, `iam`, `compute`, `database`, `monitoring`
3. Writes `plans/api-service/dev/terraform-plan.md`
4. Asks for plan approval before writing any code

---

### /build Phase

After plan approval: `/build`

The agent generates Terraform in this order:
1. `terraform/modules/networking/` — VPC, subnets, security groups
2. `terraform/modules/iam/` — ECS task role, execution role
3. `terraform/modules/database/` — RDS Aurora cluster
4. `terraform/modules/compute/` — ECS Fargate service + ALB
5. `terraform/modules/monitoring/` — CloudWatch log groups + alarms
6. `terraform/services/api-service/dev/` — Root module calling all modules

---

### /test Phase

`/test`

```
✓ terraform fmt — no diff
✓ terraform init (no backend)
✓ terraform validate
✓ tflint — 0 errors, 2 warnings (documented)
✓ terraform test — 8/8 passing
```

Report written to `validation/terraform-report.md`.

---

### /review Phase

`/review`

```
Checkov: 2 findings
  CKV_AWS_20 — S3 — EXCEPTION: serves static website (documented)
  CKV_AWS_79 — EC2 — N/A: no EC2 in this service

tfsec: 0 HIGH findings

Infracost estimate: $127/month
  ECS Fargate: $45
  RDS Aurora:  $68
  ALB:         $14
  Budget: $150/month ✓
```

Report written to `validation/security-report.md` and `validation/cost-report.md`.

---

### /ship Phase

`/ship`

Agent fills out `deployment-readiness.md` checklist and runs:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
```

Shows plan summary:
```
Plan: 24 to add, 0 to change, 0 to destroy.
```

After engineer approval:
```bash
terraform apply tfplan
```

---

## Invoking Individual Phases

You can start at any phase if prior artifacts exist:

```
/plan    ← requires: approved infrastructure-spec.yaml
/build   ← requires: approved terraform-plan.md
/test    ← requires: Terraform files exist
/review  ← requires: /test has passed
/ship    ← requires: /review has passed
```

---

## Asking Questions During a Phase

At any point you can ask:

- "What questions are still unanswered?" → Agent lists remaining discovery gaps
- "Show me the current spec" → Agent displays infrastructure-spec.yaml
- "Why did you choose ECS Fargate over Lambda?" → Agent explains from the ADR
- "What will the Terraform plan create?" → Agent lists resources from terraform-plan.md
- "Is this within budget?" → Agent shows cost estimate

---

## Updating Existing Infrastructure

### Adding a new feature (e.g., Redis cache)

```
You:   "Add a Redis cache to the api-service"
Agent: Starting /spec update for Redis cache addition...
       [abbreviated interview: cache size, eviction policy, HA needed?]
       Updating infrastructure-spec.yaml...
       Updating architecture.md...
       Writing ADR-003-cache-selection.md...
       Approved? → /plan update
```

### Promoting to a new environment

```
You:   "Set up staging for api-service"
Agent: Starting /spec for api-service/staging...
       [shorter interview: reuses workload definition, asks for staging-specific differences]
       Generates specs/api-service/staging/infrastructure-spec.yaml
       → /plan → /build (reuse modules, new tfvars) → /test → /review → /ship
```

---

## Key Boundaries

| Always | Ask First | Never |
|--------|---------|-------|
| Ask discovery questions | Changing module interfaces | Generate TF without a spec |
| Write ADRs for decisions | Adding new cloud providers | Hardcode secrets |
| Run validation before /review | Modifying CI/CD pipelines | Skip security review |
| Promote dev → staging → prod | Enabling auto-approve | Commit .tfstate files |

---

## Troubleshooting

### "The agent jumped straight to /build without asking questions"

The spec phase was skipped or requirements appeared complete. Say:
> "Stop. We haven't done /spec. Start from the beginning with the discovery interview."

### "The Terraform validate fails after /build"

The agent will follow `debugging-and-error-recovery` to diagnose. You can help by providing the exact error:
> "terraform validate failed with: [paste error]"

### "Checkov is flagging findings I don't want to fix"

Document exceptions in `validation/security-report.md` with justification. The agent will help you write the exception and determine whether it blocks /ship.

### "I want to use this for multiple services simultaneously"

Run each service as an independent workflow. Each has its own spec, plan, and state file. They share modules from `terraform/modules/` but have separate roots.

---

## Quick Reference

| Phase | Command | Key Output | Gate |
|-------|---------|-----------|------|
| Specification | `/spec` | `infrastructure-spec.yaml` + `architecture.md` | Engineer approval |
| Planning | `/plan` | `terraform-plan.md` | Engineer approval |
| Generation | `/build` | `.tf` files | `fmt` passes |
| Validation | `/test` | `terraform-report.md` | All checks exit 0 |
| Security | `/review` | `security-report.md` + `cost-report.md` | No HIGH/CRITICAL |
| Deployment | `/ship` | `deployment-readiness.md` signed | Sign-off obtained |
