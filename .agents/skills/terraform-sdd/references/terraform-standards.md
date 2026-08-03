# Terraform Coding Standards

> **Used by:** `/build` and `/review` phases of the Terraform SDD skill  
> **Purpose:** Canonical Terraform coding standards for this framework

---

## File Layout

### Service Root (`terraform/services/<service>/<env>/`)

Every service environment is a **root module** — the entry point for `terraform init/plan/apply`. It calls reusable modules; it does not define resources directly.

| File | Purpose | Required |
|------|---------|---------|
| `main.tf` | Module calls only | Yes |
| `variables.tf` | All input variable declarations | Yes |
| `outputs.tf` | All output declarations | Yes |
| `providers.tf` | Provider and Terraform version constraints | Yes |
| `backend.tf` | Remote state backend configuration | Yes |
| `locals.tf` | Local values for naming, tagging, computed strings | Yes |
| `terraform.tfvars` | Non-secret variable values | Yes (committed) |
| `data.tf` | Data source declarations | When needed |
| `versions.tf` | Alternative location for `terraform {}` block | Do not duplicate with `providers.tf` |

### Module (`terraform/modules/<capability>/`)

| File | Purpose | Required |
|------|---------|---------|
| `main.tf` | Resource definitions | Yes |
| `variables.tf` | Input variables | Yes |
| `outputs.tf` | Output values | Yes |
| `README.md` | Module documentation | Yes |
| `versions.tf` | Provider version constraints | Yes |
| `locals.tf` | Local values | When needed |
| `data.tf` | Data sources | When needed |

---

## Provider Configuration

### Version Pinning

Always pin provider versions using pessimistic constraint operators. Never use `>= x` without an upper bound.

```hcl
# providers.tf
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

**Rule:** Modules declare `required_providers` with constraints. Root modules pin exact or narrow ranges.

### Multi-Provider / Multi-Region

Use provider aliases for multi-region deployments:

```hcl
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

module "primary_networking" {
  source    = "../../../modules/networking"
  providers = { aws = aws.primary }
  # ...
}
```

---

## Backend Configuration

### Partial Backend Configuration

Never hardcode backend values. Use partial configuration (backend config supplied via `-backend-config` flag in CI/CD):

```hcl
# backend.tf
terraform {
  backend "s3" {}
}
```

```hcl
# backend.tf (Azure)
terraform {
  backend "azurerm" {}
}
```

```hcl
# backend.tf (GCP)
terraform {
  backend "gcs" {}
}
```

Supply actual values via environment-specific backend config files:

```
# backends/dev.tfbackend
bucket         = "myproject-terraform-state"
key            = "services/api-service/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
```

```bash
terraform init -backend-config=backends/dev.tfbackend
```

### State Organization

```
State file paths follow this pattern:
  services/<service-name>/<env>/terraform.tfstate

Example:
  services/api-service/dev/terraform.tfstate
  services/api-service/staging/terraform.tfstate
  services/api-service/prod/terraform.tfstate
  services/frontend/dev/terraform.tfstate
```

**Never share state files across services.** Each service+environment is an isolated state.

### State Locking

Always enable state locking:

| Backend | Lock Mechanism |
|---------|---------------|
| S3 | DynamoDB table (attribute: `LockID`) |
| Azure RM | Blob lease (automatic) |
| GCS | Object metadata lock (automatic) |

---

## Variables

### Variable Declarations

Every variable must have `type`, `description`, and optionally `default` and `validation`.

```hcl
# Good
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "instance_count" {
  type        = number
  description = "Number of compute instances to create"
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100"
  }
}

# Bad — missing type and description
variable "env" {}
```

### Variable Types

Use the most specific type possible:

```hcl
# Prefer typed collections over any
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the service"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}

variable "database_config" {
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    storage_gb     = number
    multi_az       = bool
  })
  description = "Database configuration object"
}
```

### Sensitive Variables

Mark sensitive variables so they are redacted from logs:

```hcl
variable "db_password" {
  type        = string
  description = "Database master password — supply via secrets manager, not tfvars"
  sensitive   = true
}
```

**Rule:** Sensitive variables should never have defaults. Their values should always come from:
- CI/CD secret injection
- A secrets manager data source
- `-var` flag at runtime

---

## Outputs

Every output must have a `description`. Sensitive outputs must be marked:

```hcl
# Good
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the created VPC"
}

output "database_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "Database connection endpoint"
  sensitive   = true
}

# Bad — missing description
output "vpc" {
  value = aws_vpc.main.id
}
```

### Output Naming

| Pattern | Use |
|---------|-----|
| `<resource_type>_id` | Resource IDs |
| `<resource_type>_arn` | ARNs |
| `<resource_type>_name` | Resource names |
| `<resource_type>_endpoint` | Connection endpoints |
| `<resource_type>_url` | URLs |

---

## Locals

Use `locals` for:
- Constructing resource names (never repeat the formula)
- Building common tag maps
- Computed values used in multiple places

```hcl
# locals.tf
locals {
  # Naming convention: <project>-<environment>-<descriptor>
  name_prefix = "${var.project}-${var.environment}"

  # All resources get these tags
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Service     = var.service_name
      Owner       = var.owner
      CostCenter  = var.cost_center
    },
    var.additional_tags
  )

  # Computed values
  is_production = var.environment == "prod"
  az_count      = length(var.availability_zones)
}
```

---

## Naming Conventions

### General Pattern

```
<project>-<environment>-<resource-descriptor>
```

Examples:
- `myapp-dev-api-alb`
- `myapp-prod-db-primary`
- `myapp-staging-vpc`
- `myapp-dev-cache-redis`

### Provider-Specific Constraints

| Provider | Max Length | Special Characters |
|---------|-----------|-------------------|
| AWS | Varies by service (63 for S3) | Alphanumeric + hyphens for most |
| Azure | 24 for storage accounts | Lowercase alphanumeric only for some |
| GCP | 63 for most resources | Lowercase alphanumeric + hyphens |

Use `substr()` and `replace()` when lengths are constrained:

```hcl
locals {
  # S3 bucket names: lowercase, 3-63 chars, no consecutive hyphens
  bucket_name = lower(replace("${local.name_prefix}-assets", "_", "-"))
}
```

### Tagging Standards

```hcl
# Required tags for all resources
variable "project" {
  type        = string
  description = "Project identifier for naming and tagging"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "service_name" {
  type        = string
  description = "Service name for tagging and identification"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for this infrastructure"
}

variable "cost_center" {
  type        = string
  description = "Cost center code for billing allocation"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to merge with common tags"
  default     = {}
}
```

---

## Module Design Standards

### Module Interface Design

A module's interface (`variables.tf` + `outputs.tf`) is a contract. Design it for stability:

1. **Accept primitives, not provider-specific objects** — accept `string` IDs rather than full resource objects
2. **Output what callers need** — IDs, ARNs, endpoints; not the entire resource
3. **Never output sensitive values unless necessary** — and mark them `sensitive = true`

```hcl
# Good module interface
variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create resources"
}

output "security_group_id" {
  value       = aws_security_group.app.id
  description = "ID of the application security group"
}

# Bad module interface — leaks provider details
variable "vpc" {
  type        = any  # forces caller to pass the whole aws_vpc resource
  description = "VPC resource"
}
```

### Module Versioning

When modules are extracted to separate repositories, pin versions:

```hcl
module "networking" {
  source  = "git::https://github.com/myorg/terraform-modules.git//networking?ref=v1.2.0"
  # ...
}
```

For local modules (within this repo), use relative paths:

```hcl
module "networking" {
  source = "../../../modules/networking"
  # ...
}
```

---

## Resource Lifecycle Rules

### Prevent Accidental Deletion

For stateful resources (databases, storage, state buckets):

```hcl
resource "aws_db_instance" "main" {
  # ...

  lifecycle {
    prevent_destroy = true
  }
}
```

### Ignore Changes for External Modifications

When external systems modify resources (e.g., auto-scaling modifies desired count):

```hcl
resource "aws_autoscaling_group" "app" {
  # ...

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
```

---

## Data Sources

Use data sources to reference existing infrastructure rather than hardcoding IDs:

```hcl
# Good — reference by name/tag
data "aws_vpc" "shared" {
  tags = {
    Name = "${var.project}-shared-vpc"
  }
}

# Bad — hardcoded ID that breaks across accounts/regions
resource "aws_subnet" "app" {
  vpc_id = "vpc-0abc1234"  # NEVER DO THIS
}
```

---

## Secrets Handling

### Never in Code

```hcl
# WRONG — never store secrets in variables with defaults or in tfvars
variable "db_password" {
  default = "supersecret123"  # NEVER
}

# WRONG — never reference secrets inline
resource "aws_db_instance" "main" {
  password = "hardcoded"  # NEVER
}
```

### Correct Approach — Secrets Manager Reference

```hcl
# Retrieve at plan/apply time from secrets manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "/${var.project}/${var.environment}/db/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

---

## Formatting

Run `terraform fmt -recursive` before every commit. The formatter enforces:
- 2-space indentation
- Aligned `=` in blocks with multiple arguments
- Single blank lines between blocks

Configure your editor to run `terraform fmt` on save.

---

## Anti-Patterns Reference

| Anti-Pattern | Correct Pattern |
|---|---|
| `variable "x" {}` (no type/description) | Always add `type` and `description` |
| Resources in root module | Resources go in modules; root calls modules |
| `count = 0` to disable resources | Use `for_each` or conditional module calls |
| `depends_on` everywhere | Fix the implicit dependency (use correct input/output references) |
| `terraform_remote_state` data source | Pass outputs explicitly as variables |
| Multiple providers in one module | One provider per module where possible |
| `any` type for variables | Specific types: `string`, `number`, `bool`, `list(string)`, `object({...})` |
| Inline `user_data` scripts | External file via `templatefile()` function |
| Magic string literals | `local` values with descriptive names |
