# Terraform Specification Driven Development (SDD)

> **A production-grade, AI-agent compatible workflow for designing, generating, validating, and deploying cloud infrastructure with Terraform.**

---

## 🎯 Assumptions & Target Architecture

This repository is tailored for modern cloud platform engineering with the following core stack assumptions:

* **Cloud Provider:** **AWS (Amazon Web Services)**
  * **Frontend Hosting (React / SPA / Static Web):** S3 Bucket (Private) + CloudFront CDN + Origin Access Control (OAC) + Route53 + ACM SSL/TLS.
  * **Backend API Hosting:** VPC (Multi-AZ) + ECS Fargate + Application Load Balancer (ALB) + RDS Database (PostgreSQL/MySQL).
* **CI/CD Automation:** **GitHub Actions** for automated quality gates (`fmt`, `validate`, `tflint`, `checkov`) and deployment pipelines.
* **Authentication & Security:** **AWS OIDC (OpenID Connect)** federated authentication for GitHub Actions. Zero long-lived AWS Access Keys stored in GitHub Secrets.

---

## 🛠️ Prerequisites

Before using or extending this repository on your local system or within an AI Agent environment, ensure the following prerequisites are installed and configured:

### 1. Developer CLI Tools
* **Git** (`>= 2.40`)
* **Terraform CLI** (`>= 1.6.0, < 2.0.0`)
* **AWS CLI v2** (configured for local testing/planning)
* **Node.js** (`>= 18.x`) & **npm** (if building React/frontend apps prior to deployment)

### 2. Validation & Security Tools
* **TFLint** (`>= v0.50.0`) with AWS ruleset (`tflint-ruleset-aws`)
* **Checkov** (`>= 3.0.0`) or **tfsec** (for static security policy scanning)
* **Infracost** *(optional)* for cloud cost estimation

### 3. Agent Skills Framework
This repository follows the **Agent Skills** pattern (inspired by [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) and [hashicorp/agent-skills](https://github.com/hashicorp/agent-skills)):
* Local skills are located in `.agents/skills/`:
  * `terraform-sdd` (Custom 6-phase gated lifecycle: `/spec` → `/plan` → `/build` → `/test` → `/review` → `/ship`)
  * `terraform-style-guide` (Official HashiCorp code style conventions)
  * `terraform-test` (Native HCL unit & integration testing)
  * `refactor-module` (Terraform module refactoring patterns)
  * `terraform-policy` (Sentinel & OPA policy enforcement)
  * `azure-verified-modules` / `terraform-stacks` / `terraform-search-import`

### 4. AWS OIDC Configuration (for GitHub Actions)
To enable secure automated deployments via GitHub Actions:
1. Create an AWS IAM OIDC Identity Provider for `https://token.actions.githubusercontent.com`.
2. Create an IAM Role (e.g., `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-role`) trusting `repo:<your-github-org>/<your-repo-name>:*`.
3. Update `OIDC_ROLE_ARN` in `.github/workflows/terraform-plan.yml`, `terraform-apply.yml`, and `terraform-destroy.yml`.

---

## 🚀 Quick Start

### As an Engineer with an AI Assistant

Describe what you need to build:

> *"I want to host my React app on AWS using S3 and CloudFront. Let's start with `/spec`."*

The agent will execute the 6-phase gated lifecycle:
1. **`/spec`** — Infrastructure discovery interview → `specs/<service>/<env>/infrastructure-spec.yaml`
2. **`/plan`** — Architecture design & ADRs → `specs/<service>/<env>/architecture.md` & `plans/`
3. **`/build`** — Terraform code generation → `terraform/modules/` + `terraform/services/`
4. **`/test`** — Quality checks → `terraform fmt` + `validate` + `tflint`
5. **`/review`** — Security & cost checks → Checkov + Infracost
6. **`/ship`** — Deployment readiness sign-off & GitHub Actions deployment

### Slash Commands

| Command | Phase | Description |
|---------|-------|-------------|
| `/spec` | 1 | Discovery interview → `infrastructure-spec.yaml` |
| `/plan` | 2 | Architecture document & ADR decisions |
| `/build` | 3 | Terraform module and service root generation |
| `/test` | 4 | `fmt` + `validate` + `tflint` + unit tests |
| `/review` | 5 | Security scanning + cost estimation |
| `/ship` | 6 | Deployment readiness checklist + CI/CD apply |

---

## 📁 Repository Structure

```
.
├── .agents/
│   ├── AGENTS.md                          ← Workspace rules and Terraform conventions
│   └── skills/
│       ├── terraform-sdd/                 ← Core 6-phase SDD lifecycle skill
│       ├── terraform-style-guide/         ← Official HashiCorp style guide
│       ├── terraform-test/                ← HashiCorp testing skill
│       └── ...                            ← Additional HashiCorp skills
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml             ← CI Plan, Validate, TFLint, Checkov scan
│       ├── terraform-apply.yml            ← CD Apply with OIDC & approval gates
│       └── terraform-destroy.yml          ← CD Manual Destroy with approval gates
│
├── terraform/
│   ├── services/                          ← Per-service, per-environment Terraform roots
│   └── modules/                           ← Reusable capability modules (networking, compute, etc.)
│
├── specs/                                 ← Infrastructure specs, architecture, ADRs
├── plans/                                 ← Detailed technical plans
├── validation/                            ← Linting, security, and cost reports
├── templates/                             ← Spec & plan templates
├── SPEC.md                                ← Master framework specification
└── README.md                              ← This file
```

---

## 🔐 Authentication & Security Model

```
 ┌──────────────────────┐         OIDC Token Exchange         ┌────────────────────────┐
 │                      │ ──────────────────────────────────> │                        │
 │  GitHub Actions CI   │                                     │     AWS IAM Role       │
 │  (Runner Execution)  │ <────────────────────────────────── │  (Short-lived creds)   │
 └──────────────────────┘       AssumeRoleWithWebIdentity     └────────────────────────┘
            │                                                              │
            ▼                                                              ▼
 ┌──────────────────────┐                                     ┌────────────────────────┐
 │  Terraform Execution │ ──────────────────────────────────> │     AWS Cloud Infra    │
 │ (Init/Plan/Apply)    │                                     │  (S3, CloudFront, etc) │
 └──────────────────────┘                                     └────────────────────────┘
```

1. **Zero Permanent Credentials:** No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in GitHub Secrets.
2. **Short-Lived Tokens:** GitHub Actions requests temporary AWS STS tokens using OIDC tokens (`id-token: write`).
3. **Scoped Roles:** IAM roles are restricted by repository, branch, and environment.

---

## 📋 Terraform Standards

* **Module Design:** Capability-focused (`networking`, `compute`, `database`, `storage`).
* **Tagging:** Mandatory default tags on all resources (`Project`, `Environment`, `ManagedBy`, `Service`, `Owner`, `CostCenter`).
* **Secrets:** Injected exclusively via `TF_VAR_` environment variables or Secrets Manager in CI/CD pipelines. Never committed to `.tfvars`.
* **State Management:** Remote backend (S3 + DynamoDB locking) with partial CLI configuration.

---

## 💡 Suggested Repository Names

If you are pushing this framework to a new GitHub repository, here are recommended repository names:

1. `spec-driven-terraform` *(Current default — clean & descriptive)*
2. `terraform-sdd-framework` *(Emphasizes Specification Driven Development)*
3. `aws-terraform-sdd` *(Highlights AWS + SDD target stack)*
4. `cloud-sdd-engine` *(Broader platform engineering focus)*
5. `tf-spec-ops` *(Short & catchy)*

---

## 📄 License & References

- Built using the Agent Skills pattern from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
- Integrated with official HashiCorp Agent Skills from [hashicorp/agent-skills](https://github.com/hashicorp/agent-skills).
