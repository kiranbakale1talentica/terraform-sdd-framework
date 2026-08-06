terraform {
  backend "s3" {
    bucket       = "terraform-sdd-tfstate-682563173581"
    key          = "services/first-s3-bucket/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
