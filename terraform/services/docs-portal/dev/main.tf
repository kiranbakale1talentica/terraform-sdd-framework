module "frontend_hosting" {
  source = "../../../modules/frontend-hosting"

  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  owner       = var.owner
  cost_center = var.cost_center
}
