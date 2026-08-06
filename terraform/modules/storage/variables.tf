variable "project_prefix" {
  type        = string
  description = "Project prefix used in resource naming and tagging"
  default     = "terraform-sdd"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)"
}

variable "bucket_name_suffix" {
  type        = string
  description = "Unique suffix descriptor for bucket naming (e.g. first-storage)"
}

variable "owner" {
  type        = string
  description = "Team or individual owner responsible for this resource"
  default     = "DevOps"
}

variable "cost_center" {
  type        = string
  description = "Cost center or billing code for resource tagging"
  default     = "DevOps-101"
}

variable "enable_versioning" {
  type        = bool
  description = "Controls whether object versioning is enabled for the S3 bucket"
  default     = true
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "Number of days after which non-current object versions transition to STANDARD_IA storage class"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the S3 bucket"
  default     = {}
}
