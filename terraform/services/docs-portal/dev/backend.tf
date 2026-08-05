terraform {
  backend "s3" {
    bucket       = "terraform-sdd-tfstate-682563173581"
    key          = "services/docs-portal/dev/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
