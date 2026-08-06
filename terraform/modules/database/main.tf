locals {
  table_name = lower("${var.project_prefix}-${var.service_name}-${var.environment}")

  default_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = var.service_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  merged_tags = merge(local.default_tags, var.tags)
}

resource "aws_dynamodb_table" "main" {
  name         = local.table_name
  billing_mode = var.billing_mode

  hash_key  = "user_id"
  range_key = "created_at"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  server_side_encryption {
    enabled = var.enable_encryption
  }

  tags = merge(local.merged_tags, {
    Name = local.table_name
  })
}
