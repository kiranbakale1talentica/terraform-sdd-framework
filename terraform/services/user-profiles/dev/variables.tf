variable "aws_region" {
  type        = string
  description = "AWS region for infrastructure deployment"
  default     = "ap-south-1"
}

variable "project_prefix" {
  type        = string
  description = "Project name prefix used for resource naming and tagging"
  default     = "terraform-sdd"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g. dev, staging, prod)"
  default     = "dev"
}

variable "service_name" {
  type        = string
  description = "Name of the service being provisioned"
  default     = "user-profiles"
}

variable "billing_mode" {
  type        = string
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  default     = "PAY_PER_REQUEST"
}

variable "enable_pitr" {
  type        = bool
  description = "Enable Point-In-Time Recovery continuous backup"
  default     = true
}

variable "enable_encryption" {
  type        = bool
  description = "Enable server-side encryption"
  default     = true
}

variable "owner" {
  type        = string
  description = "Team or individual owner responsible for this service"
  default     = "User Service Team"
}

variable "cost_center" {
  type        = string
  description = "Cost center code for billing"
  default     = "DevOps-102"
}
