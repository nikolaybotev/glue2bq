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

# Grant Cloud Storage service account access to KMS key
resource "google_kms_crypto_key_iam_binding" "gcs_cmek_binding" {
  crypto_key_id = google_kms_crypto_key.gcs_cmek.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
  ]
}

resource "google_storage_bucket" "data_bucket" {
  name          = "${local.resource_prefix}-data-bucket"
  location      = var.gcp_region
  force_destroy = false

  # Enable uniform bucket-level access as required by organization policy
  uniform_bucket_level_access = true

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

  depends_on = [google_kms_crypto_key_iam_binding.gcs_cmek_binding]
}

# BigQuery Single-Region Dataset
resource "google_bigquery_dataset" "default" {
  dataset_id  = "default"
  friendly_name = "Default Dataset"
  description   = "Dummy BigQuery single-region dataset"
  location      = var.gcp_region
}
