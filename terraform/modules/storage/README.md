# Storage Capability Module

This module provisions a production-ready AWS S3 bucket with default-deny public access, SSE-S3 AES256 encryption, native versioning, and lifecycle transition rules for non-current versions.

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  project_prefix      = "terraform-sdd"
  environment         = "dev"
  bucket_name_suffix  = "first-storage"
  owner               = "DevOps"
  cost_center         = "DevOps-101"
  enable_versioning   = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name_suffix` | Unique suffix descriptor for bucket naming | `string` | n/a | yes |
| `cost_center` | Cost center or billing code | `string` | `"DevOps-101"` | no |
| `enable_versioning` | Controls whether object versioning is enabled | `bool` | `true` | no |
| `environment` | Deployment environment | `string` | n/a | yes |
| `noncurrent_version_transition_days` | Days before noncurrent versions transition to STANDARD_IA | `number` | `30` | no |
| `owner` | Team or individual owner | `string` | `"DevOps"` | no |
| `project_prefix` | Project prefix used in resource naming and tagging | `string` | `"terraform-sdd"` | no |
| `tags` | Additional tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `s3_bucket_arn` | The Amazon Resource Name (ARN) of the created S3 bucket |
| `s3_bucket_domain_name` | The bucket domain name of the created S3 bucket |
| `s3_bucket_id` | The name/ID of the created S3 bucket |
| `s3_bucket_regional_domain_name` | The regional bucket domain name of the created S3 bucket |
