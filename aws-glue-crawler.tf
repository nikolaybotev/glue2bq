# AWS Glue Crawler
resource "aws_glue_crawler" "iceberg_crawler" {
  name          = "test"  # Your actual crawler name
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.main.name

  s3_target {
    path = "s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/"
  }

  configuration = jsonencode({
    "Version" = 1
    "CreatePartitionIndex" = true
  })

  tags = merge(local.common_tags, {
    Name = "test"
  })
}

# IAM Policy for Glue Crawler (S3 and KMS access)
resource "aws_iam_policy" "glue_crawler_s3_policy" {
  name        = "${local.resource_prefix}-glue-crawler-policy"
  description = "Policy for Glue Crawler to access S3 bucket and KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
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
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables"
        ]
        Resource = [
          aws_glue_catalog_database.main.arn,
          "${aws_glue_catalog_database.main.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "glue_crawler_role" {
  name               = "AWSGlueServiceRole-crawl"
  path               = "/service-role/"  # Match the existing path
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Attach our new policy to the role
resource "aws_iam_role_policy_attachment" "glue_crawler_custom_policy" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_s3_policy.arn
}

# Keep the AWS managed policy for basic Glue permissions
resource "aws_iam_role_policy_attachment" "glue_crawler_service_role" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
