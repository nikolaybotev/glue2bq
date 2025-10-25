# AWS Role for BigQuery Omni Connection
resource "aws_iam_role" "bigquery_omni_role" {
  name = "${local.resource_prefix}-bigquery-omni-role"

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
            "accounts.google.com:aud" = "bigquery-omni"
          }
          StringLike = {
            "accounts.google.com:sub" = "serviceAccount:*@${var.gcp_project_id}.iam.gserviceaccount.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-bigquery-omni-role"
  })
}

resource "aws_iam_policy" "bigquery_omni_policy" {
  name        = "${local.resource_prefix}-bigquery-omni-policy"
  description = "Policy for BigQuery Omni to access AWS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartitions",
          "glue:GetPartition",
          "glue:BatchGetPartition"
        ]
        Resource = [
          aws_glue_catalog_database.main.arn,
          "${aws_glue_catalog_database.main.arn}/*"
        ]
      },
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
        Resource = [
          aws_kms_key.s3_cmek.arn,
          aws_kms_key.glue_catalog_cmek.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bigquery_omni_policy_attachment" {
  role       = aws_iam_role.bigquery_omni_role.name
  policy_arn = aws_iam_policy.bigquery_omni_policy.arn
}

# BigQuery Omni Connection
resource "google_bigquery_connection" "aws_omni" {
  connection_id = "${local.resource_prefix}-aws-omni"
  location      = var.gcp_region
  friendly_name = "AWS Omni Connection"
  description   = "BigQuery Omni connection to AWS"

  aws {
    access_role {
      iam_role_id = aws_iam_role.bigquery_omni_role.arn
    }
  }
}

# BigQuery External Dataset
resource "google_bigquery_dataset" "external_dataset" {
  dataset_id    = "${replace(local.resource_prefix, "-", "_")}_external_dataset"
  friendly_name = "External Dataset from AWS Glue"
  description   = "External dataset using BigQuery Omni connection to AWS Glue"
  location      = var.gcp_region

  access {
    role          = "OWNER"
    user_by_email = data.google_client_config.current.access_token
  }
}

# BigQuery External Table
resource "google_bigquery_table" "external_table" {
  dataset_id = google_bigquery_dataset.external_dataset.dataset_id
  table_id   = "sample_iceberg_table"

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/sample_table/data/*"]

    connection_id = google_bigquery_connection.aws_omni.name
  }

  depends_on = [google_bigquery_connection.aws_omni]
}
