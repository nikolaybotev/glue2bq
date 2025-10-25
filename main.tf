terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# GCP Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  # Set quota project for Access Context Manager API
  billing_project = var.gcp_project_id
  # Set user project override for APIs that require it
  user_project_override = true
}

# Data sources
data "aws_caller_identity" "current" {}
data "google_client_config" "current" {}
data "google_project" "current" {
  project_id = var.gcp_project_id
}
