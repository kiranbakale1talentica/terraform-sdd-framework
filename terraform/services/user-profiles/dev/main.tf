module "database" {
  source = "../../../modules/database"

  project_prefix    = var.project_prefix
  environment       = var.environment
  service_name      = var.service_name
  billing_mode      = var.billing_mode
  enable_pitr       = var.enable_pitr
  enable_encryption = var.enable_encryption
  owner             = var.owner
  cost_center       = var.cost_center
  tags              = local.common_tags
}
