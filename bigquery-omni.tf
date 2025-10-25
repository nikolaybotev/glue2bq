# AWS Role for BigQuery Omni Connection
resource "aws_iam_role" "bigquery_omni_role" {
  name = local.bigquery_omni_role_name

  # Set maximum session duration to 12 hours for BigQuery Omni
  max_session_duration = 43200  # 12 hours in seconds

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
            "accounts.google.com:sub" = google_bigquery_connection.aws_omni.aws[0].access_role[0].identity
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.bigquery_omni_role_name
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
  location      = "aws-${var.aws_region}"  # AWS region with aws- prefix
  friendly_name = "AWS Omni Connection"
  description   = "BigQuery Omni connection to AWS"

  aws {
    access_role {
      iam_role_id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.bigquery_omni_role_name}"
    }
  }
}

# BigQuery External Dataset
resource "google_bigquery_dataset" "external_dataset" {
  dataset_id    = "${replace(local.resource_prefix, "-", "_")}_external_dataset"
  friendly_name = "External Dataset from AWS Glue"
  description   = "External dataset using BigQuery Omni connection to AWS Glue"
  location      = "aws-${var.aws_region}"  # Must match the BigQuery Omni connection region

  external_dataset_reference {
    external_source = "aws-glue://${aws_glue_catalog_database.main.arn}"
    connection      = google_bigquery_connection.aws_omni.name
  }
}
