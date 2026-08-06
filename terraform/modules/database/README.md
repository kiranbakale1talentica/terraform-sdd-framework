# Database Capability Module (DynamoDB)

This capability module provisions a production-ready AWS DynamoDB NoSQL table with `PAY_PER_REQUEST` On-Demand billing, Global Secondary Indexing (`email-index`), Point-In-Time Recovery (PITR), and Server-Side Encryption (KMS).

## Usage

```hcl
module "database" {
  source = "../../modules/database"

  project_prefix    = "terraform-sdd"
  environment       = "dev"
  service_name      = "user-profiles"
  billing_mode      = "PAY_PER_REQUEST"
  enable_pitr       = true
  enable_encryption = true
  owner             = "User Service Team"
  cost_center       = "DevOps-102"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `billing_mode` | Billing mode (`PAY_PER_REQUEST` or `PROVISIONED`) | `string` | `"PAY_PER_REQUEST"` | no |
| `cost_center` | Cost center or billing code | `string` | `"DevOps-102"` | no |
| `enable_encryption` | Controls server-side encryption | `bool` | `true` | no |
| `enable_pitr` | Controls Point-In-Time Recovery continuous backup | `bool` | `true` | no |
| `environment` | Deployment environment | `string` | n/a | yes |
| `owner` | Team or individual owner | `string` | `"User Service Team"` | no |
| `project_prefix` | Project prefix used in resource naming and tagging | `string` | `"terraform-sdd"` | no |
| `service_name` | Name of the service | `string` | n/a | yes |
| `tags` | Additional tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `dynamodb_table_arn` | The Amazon Resource Name (ARN) of the created DynamoDB table |
| `dynamodb_table_id` | The name/ID of the created DynamoDB table |
| `dynamodb_table_name` | The name of the created DynamoDB table |
