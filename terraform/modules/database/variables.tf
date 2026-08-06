variable "project_prefix" {
  type        = string
  description = "Project prefix used for naming and tagging"
  default     = "terraform-sdd"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)"
}

variable "service_name" {
  type        = string
  description = "Name of the service (e.g. user-profiles)"
}

variable "billing_mode" {
  type        = string
  description = "Controls how you are charged for read and write throughput (PAY_PER_REQUEST or PROVISIONED)"
  default     = "PAY_PER_REQUEST"
}

variable "enable_pitr" {
  type        = bool
  description = "Enable Point-In-Time Recovery continuous backup"
  default     = true
}

variable "enable_encryption" {
  type        = bool
  description = "Enable server-side encryption using AWS managed KMS key"
  default     = true
}

variable "owner" {
  type        = string
  description = "Team or individual owner responsible for this resource"
  default     = "User Service Team"
}

variable "cost_center" {
  type        = string
  description = "Cost center or billing code"
  default     = "DevOps-102"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the DynamoDB table"
  default     = {}
}
