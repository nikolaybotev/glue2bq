# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "glue2bq"
}

variable "vpn_ip_subnetworks" {
  description = "List of IP subnetwork ranges for VPN access (CIDR notation)"
  type        = list(string)
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # Extract AWS IAM role name to break circular dependency
  bigquery_omni_role_name = "${local.resource_prefix}-bigquery-omni-role"
}
