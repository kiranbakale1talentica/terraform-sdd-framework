variable "aws_region" {
  type        = string
  description = "AWS region for infrastructure deployment"
  default     = "ap-south-1"
}

variable "project_prefix" {
  type        = string
  description = "Project name prefix used for naming resources and tagging"
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
  default     = "first-s3-bucket"
}

variable "bucket_name_suffix" {
  type        = string
  description = "Unique suffix descriptor for the S3 bucket"
  default     = "first-storage"
}

variable "owner" {
  type        = string
  description = "Team or individual owner responsible for this service"
  default     = "DevOps"
}

variable "cost_center" {
  type        = string
  description = "Cost center code for billing"
  default     = "DevOps-101"
}

variable "enable_versioning" {
  type        = bool
  description = "Controls whether object versioning is enabled"
  default     = true
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "Days before non-current object versions transition to STANDARD_IA storage class"
  default     = 30
}
