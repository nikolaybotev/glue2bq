# GCS Bucket with CMEK
resource "google_kms_key_ring" "gcs_cmek" {
  name     = "${local.resource_prefix}-gcs-cmek"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "gcs_cmek" {
  name            = "${local.resource_prefix}-gcs-cmek-key"
  key_ring        = google_kms_key_ring.gcs_cmek.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "data_bucket" {
  name          = "${local.resource_prefix}-data-bucket"
  location      = var.gcp_region
  force_destroy = false

  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs_cmek.id
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}
