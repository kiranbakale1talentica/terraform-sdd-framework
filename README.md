# Terraform SDD Framework

> **A cloud-provider-neutral starter kit for Specification Driven Development (SDD) of cloud infrastructure with Terraform.**

---

## What Is This?

This is a **starter kit** — not a ready-to-deploy stack. It gives you a reusable, AI-agent-compatible workflow and repository structure so your team can design, generate, validate, and deploy cloud infrastructure in a consistent, auditable way.

It enforces a structured **6-phase gated lifecycle** before any `terraform apply` ever runs:

```
/spec → /plan → /build → /test → /review → /ship
```

---

## Default Stack (Override Per Project)

| Component | Default |
|-----------|---------|
| **Cloud** | Configured during `/spec` — AWS, Azure, GCP, or multi-cloud |
| **CI/CD** | GitHub Actions (`.github/workflows/`) |
| **Auth** | OIDC federated identity (no long-lived credentials) |
| **IaC** | Terraform `>= 1.6.0` |
| **Quality** | TFLint + Checkov + Infracost |

---

## Prerequisites

Before using this starter kit, install the following on your system:

### Developer Tools
| Tool | Version | Install |
|------|---------|---------|
| Git | `>= 2.40` | [git-scm.com](https://git-scm.com/) |
| Terraform CLI | `>= 1.6.0` | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Pre-commit | Latest | `pip install pre-commit` |
| AWS CLI v2 *(if using AWS)* | Latest | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |

### Validation & Security Tools
| Tool | Purpose | Install |
|------|---------|---------|
| TFLint | Terraform best-practice linting | [tflint.io](https://github.com/terraform-linters/tflint) |
| Checkov | Security policy scanning | `pip install checkov` |
| Gitleaks | Secret detection in commits | [gitleaks.io](https://github.com/gitleaks/gitleaks) |
| Infracost *(optional)* | Cloud cost estimation | [infracost.io](https://www.infracost.io/) |
| terraform-docs *(optional)* | Auto-generate module docs | [terraform-docs.io](https://terraform-docs.io/) |

### Agent Skills (AI Assistant Integration)
This framework is designed to work with AI coding agents that support the Agent Skills pattern:
- **[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** — Core skill protocol
- **[hashicorp/agent-skills](https://github.com/hashicorp/agent-skills)** — Official HashiCorp Terraform skills

Skills are pre-installed in `.agents/skills/`. No additional setup needed.

---

## Getting Started

### 1. Clone this Repository

```bash
git clone https://github.com/kiranbakale1talentica/terraform-sdd-framework.git my-infra
cd my-infra
```

### 2. Install Pre-commit Hooks

```bash
pre-commit install
```

### 3. Configure Your Cloud Credentials

Follow your cloud provider's guide for local authentication:
- **AWS:** `aws configure` or set up `AWS_PROFILE`
- **Azure:** `az login`
- **GCP:** `gcloud auth application-default login`

### 4. Set Up GitHub Actions OIDC (For CI/CD)

Configure your cloud provider to trust GitHub Actions via OIDC (no access keys needed):
- **AWS:** [docs.github.com — AWS OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- **Azure:** [docs.github.com — Azure OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- **GCP:** [docs.github.com — GCP OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)

Then update the `OIDC_ROLE_ARN` (or equivalent) in your `.github/workflows/*.yml` files.

### 5. Start Your First Infrastructure Spec

Copy the default spec and fill it in:

```bash
mkdir -p specs/my-service/dev
cp specs/default-spec.yaml specs/my-service/dev/infrastructure-spec.yaml
```

Or, with an AI assistant, simply say:
> *"I want to provision infrastructure for my service. Let's start with `/spec`."*

---

## Workflow — The 6 Phases

### `/spec` — Discovery & Specification
The agent interviews you about your workload and writes a complete `infrastructure-spec.yaml`.

**Output:** `specs/<service>/<env>/infrastructure-spec.yaml`

### `/plan` — Architecture & Decisions
The agent designs the architecture, selects services, and logs every decision as an ADR.

**Output:** `specs/<service>/<env>/architecture.md` + `decisions/ADR-NNN-*.md`

### `/build` — Code Generation
Terraform HCL is generated following HashiCorp's official style guide and your spec.

**Output:** `terraform/modules/` + `terraform/services/<service>/<env>/`

### `/test` — Quality Gates
Automated checks run locally and in CI:
```bash
terraform fmt -recursive -check
terraform init -backend=false && terraform validate
tflint --recursive
```

### `/review` — Security & Cost
A security scan and cost estimate are produced before any deployment is approved.
```bash
checkov -d . --framework terraform
infracost breakdown --path .
```

### `/ship` — Deploy
The `deployment-readiness.md` checklist is reviewed and signed off. The GitHub Actions apply workflow is triggered.

---

## Repository Structure

```
.
├── .agents/                     ← AI agent rules and Terraform skills
│   ├── AGENTS.md                ← Workspace conventions and phase gate rules
│   └── skills/                  ← Auto-loaded skill definitions
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml   ← PR: fmt, lint, checkov, plan
│       ├── terraform-apply.yml  ← Main: deploy with approval gates
│       └── terraform-destroy.yml← Manual: teardown with approval gate
│
├── .pre-commit-config.yaml      ← Pre-commit hooks (fmt, secrets, validate)
├── .tflint.hcl                  ← TFLint configuration
│
├── terraform/
│   ├── services/                ← Per-service, per-environment Terraform roots
│   └── modules/                 ← Reusable capability modules
│
├── specs/
│   └── default-spec.yaml        ← Default starter spec (copy for new services)
│
├── plans/                       ← Technical plan documents
├── validation/                  ← Lint, security, and cost reports
├── templates/                   ← Document templates for each phase
├── SPEC.md                      ← Framework master specification
└── README.md                    ← This file
```

---

## Pre-commit Hooks

This kit ships with a `.pre-commit-config.yaml` that runs automatically before every git commit:

| Hook | What It Checks |
|------|---------------|
| `terraform_fmt` | HCL formatting is canonical |
| `terraform_validate` | Syntax and type errors |
| `terraform_tflint` | Best-practice violations |
| `terraform_docs` | Module docs are up to date |
| `gitleaks` | No secrets or credentials committed |
| `check-yaml` / `check-json` | Valid YAML and JSON files |
| `detect-private-key` | No private keys committed |

---

## Terraform Coding Standards

- Modules represent **capabilities** (e.g., `networking`, `compute`, `database`), not services
- All variables have `type` and `description`
- All outputs have `description`
- No hardcoded secrets, account IDs, regions, or passwords
- Backend uses **partial configuration** — environment-specific values injected at CI time
- Provider versions pinned with `~>` pessimistic constraint

---

## CI/CD Authentication

This starter kit uses **OIDC federated identity** for all cloud deployments. This means GitHub Actions receives short-lived cloud credentials without any permanent access keys.

See [SPEC.md](SPEC.md) for the full security baseline and [docs/workflow.md](docs/workflow.md) for the end-to-end workflow guide.

---

## References

- HashiCorp Terraform Style Guide — [developer.hashicorp.com](https://developer.hashicorp.com/terraform/language/style)
- HashiCorp Agent Skills — [github.com/hashicorp/agent-skills](https://github.com/hashicorp/agent-skills)
- Agent Skills Pattern — [github.com/addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
- pre-commit-terraform — [github.com/antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
