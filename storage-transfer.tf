# AWS Role for Storage Transfer Job
resource "aws_iam_role" "storage_transfer_role" {
  name = "${local.resource_prefix}-storage-transfer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "accounts.google.com"
        }
        Condition = {
          StringEquals = {
            "accounts.google.com:aud" = "storage-transfer-service"
          }
          StringLike = {
            "accounts.google.com:sub" = "serviceAccount:*@${var.gcp_project_id}.iam.gserviceaccount.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-storage-transfer-role"
  })
}

resource "aws_iam_policy" "storage_transfer_policy" {
  name        = "${local.resource_prefix}-storage-transfer-policy"
  description = "Policy for Storage Transfer Service to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.s3_cmek.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "storage_transfer_policy_attachment" {
  role       = aws_iam_role.storage_transfer_role.name
  policy_arn = aws_iam_policy.storage_transfer_policy.arn
}

# Grant Storage Transfer service account access to GCS bucket
resource "google_storage_bucket_iam_member" "storage_transfer_gcs_access" {
  bucket = google_storage_bucket.data_bucket.name
  role   = "roles/storage.admin"
  # project-289720198442@storage-transfer-service.iam.gserviceaccount.com
  member = "serviceAccount:project-${data.google_project.current.number}@storage-transfer-service.iam.gserviceaccount.com"
}

# Storage Transfer Job
resource "google_storage_transfer_job" "s3_to_gcs" {
  description = "Transfer data from S3 to GCS"
  project     = var.gcp_project_id

  transfer_spec {
    aws_s3_data_source {
      bucket_name = aws_s3_bucket.data_bucket.bucket
      aws_access_key {
        access_key_id     = aws_iam_access_key.storage_transfer.id
        secret_access_key = aws_iam_access_key.storage_transfer.secret
      }
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.data_bucket.name
    }
  }

  schedule {
    schedule_start_date {
      year  = 2024
      month = 1
      day   = 1
    }
    schedule_end_date {
      year  = 2025
      month = 12
      day   = 31
    }
    start_time_of_day {
      hours   = 0
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }

  depends_on = [aws_iam_access_key.storage_transfer, google_storage_bucket_iam_member.storage_transfer_gcs_access]
}

# IAM Access Key for Storage Transfer (Note: This is a simplified approach)
# In production, you should use IAM roles with web identity federation
resource "aws_iam_access_key" "storage_transfer" {
  user = aws_iam_user.storage_transfer.name
}

resource "aws_iam_user" "storage_transfer" {
  name = "${local.resource_prefix}-storage-transfer-user"
  path = "/"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-storage-transfer-user"
  })
}

resource "aws_iam_user_policy_attachment" "storage_transfer_user_policy" {
  user       = aws_iam_user.storage_transfer.name
  policy_arn = aws_iam_policy.storage_transfer_policy.arn
}
