variables {
  project_prefix     = "test"
  environment        = "unit"
  bucket_name_suffix = "test-bucket"
  owner              = "DevOps"
  cost_center        = "Test-001"
}

run "verify_bucket_security_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true
    error_message = "Public ACLs must be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_policy == true
    error_message = "Public policies must be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.ignore_public_acls == true
    error_message = "Ignore public ACLs must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.restrict_public_buckets == true
    error_message = "Restrict public buckets must be true"
  }
}
