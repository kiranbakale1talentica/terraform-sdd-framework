locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = var.service_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}
