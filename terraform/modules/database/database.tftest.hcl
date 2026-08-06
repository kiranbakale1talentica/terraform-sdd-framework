variables {
  project_prefix    = "test"
  environment       = "unit"
  service_name      = "user-profiles"
  billing_mode      = "PAY_PER_REQUEST"
  enable_pitr       = true
  enable_encryption = true
  owner             = "User Service Team"
  cost_center       = "Test-002"
}

run "verify_dynamodb_table_configuration" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.main.billing_mode == "PAY_PER_REQUEST"
    error_message = "Billing mode must be PAY_PER_REQUEST"
  }

  assert {
    condition     = aws_dynamodb_table.main.hash_key == "user_id"
    error_message = "Partition key must be user_id"
  }

  assert {
    condition     = aws_dynamodb_table.main.range_key == "created_at"
    error_message = "Sort key must be created_at"
  }

  assert {
    condition     = aws_dynamodb_table.main.point_in_time_recovery[0].enabled == true
    error_message = "Point-in-time recovery must be enabled"
  }

  assert {
    condition     = aws_dynamodb_table.main.server_side_encryption[0].enabled == true
    error_message = "Server-side encryption must be enabled"
  }
}
