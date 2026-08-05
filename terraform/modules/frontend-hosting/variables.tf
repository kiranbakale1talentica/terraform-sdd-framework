variable "project" {
  type        = string
  description = "Project name used in resource naming and tagging"
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev, staging, prod)"
}

variable "domain_name" {
  type        = string
  description = "Target custom domain name (e.g., docs.example.com)"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for this infrastructure"
}

variable "cost_center" {
  type        = string
  description = "Billing cost center code"
}
