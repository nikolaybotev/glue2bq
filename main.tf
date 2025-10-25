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
}

# Data sources
data "aws_caller_identity" "current" {}
data "google_client_config" "current" {}
