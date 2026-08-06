# Validation Report: user-profiles — dev

> **Status:** Passed  
> **Date:** 2026-08-06  
> **Target:** `terraform/services/user-profiles/dev` and `terraform/modules/database`

---

## Validation Summary

| Check | Tool / Command | Status | Result |
| :--- | :--- | :--- | :--- |
| **Format** | `terraform fmt -recursive -check` | PASS | Zero formatting diffs |
| **Module Init & Validate** | `terraform init -backend=false && terraform validate` | PASS | Success! The configuration is valid. |
| **Unit Test** | `terraform test` | PASS | 1 passed, 0 failed (`database.tftest.hcl`) |
| **Service Root Init & Validate** | `terraform init -backend=false && terraform validate` | PASS | Success! Service root configuration is valid. |

---

## Detailed Test Output

### 1. `terraform fmt` Check
```
Pass - Zero formatting differences across modules/database and services/user-profiles/dev.
```

### 2. `terraform test` Unit Test Execution
```
database.tftest.hcl... in progress
  run "verify_dynamodb_table_configuration"... pass
database.tftest.hcl... tearing down
database.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

### 3. `terraform validate` Results
```
Success! The configuration is valid.
```
