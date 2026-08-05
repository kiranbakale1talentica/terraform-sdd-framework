# Unit Test for Frontend Hosting Module
# Command: plan (fast, dry-run, no real cloud resources created)

variables {
  project     = "test-proj"
  environment = "dev"
  domain_name = "test.example.com"
  owner       = "platform-team"
  cost_center = "cc-1234"
}

provider "aws" {
  region                      = "us-west-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

run "validate_bucket_and_tags" {
  command = plan

  override_data {
    target = data.aws_route53_zone.this
    values = {
      zone_id = "Z1234567890AAA"
      arn     = "arn:aws:route53:::hostedzone/Z1234567890AAA"
    }
  }

  assert {
    condition     = aws_s3_bucket.assets.bucket == "test-proj-dev-assets"
    error_message = "Bucket name should follow the project-environment-assets naming convention"
  }

  assert {
    condition     = aws_s3_bucket.assets.tags["Environment"] == "dev"
    error_message = "Environment tag must match input variable"
  }

  assert {
    condition     = aws_s3_bucket.assets.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must be set to terraform"
  }
}
