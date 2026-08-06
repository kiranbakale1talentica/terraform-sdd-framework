module "storage" {
  source = "../../../modules/storage"

  project_prefix                     = var.project_prefix
  environment                        = var.environment
  bucket_name_suffix                 = var.bucket_name_suffix
  owner                              = var.owner
  cost_center                        = var.cost_center
  enable_versioning                  = var.enable_versioning
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  tags                               = local.common_tags
}
