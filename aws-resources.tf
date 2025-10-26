# S3 Bucket with CMEK
resource "aws_kms_key" "s3_cmek" {
  description             = "CMEK for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Glue Service"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-s3-cmek"
  })
}

resource "aws_kms_alias" "s3_cmek" {
  name          = "alias/${local.resource_prefix}-s3-cmek"
  target_key_id = aws_kms_key.s3_cmek.key_id
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${local.resource_prefix}-data-bucket"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-data-bucket"
  })
}

resource "aws_s3_bucket_versioning" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_cmek.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CMEK for AWS Glue Catalog Metadata encryption
resource "aws_kms_key" "glue_catalog_cmek" {
  description             = "CMEK for AWS Glue Catalog Metadata encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow BigQuery Omni to Decrypt the Glue Catalog CMEK"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${local.bigquery_omni_role_name}/bigqueryomni"
        }
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-glue-catalog-cmek"
  })
}

resource "aws_kms_alias" "glue_catalog_cmek" {
  name          = "alias/${local.resource_prefix}-glue-catalog-cmek"
  target_key_id = aws_kms_key.glue_catalog_cmek.key_id
}

# AWS Glue Catalog Metadata encryption configuration
resource "aws_glue_data_catalog_encryption_settings" "main" {
  data_catalog_encryption_settings {
    connection_password_encryption {
      aws_kms_key_id                       = aws_kms_key.glue_catalog_cmek.arn
      return_connection_password_encrypted = true
    }
    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = aws_kms_key.glue_catalog_cmek.arn
    }
  }
}
