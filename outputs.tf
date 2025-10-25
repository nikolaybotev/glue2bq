# Outputs
output "aws_s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "aws_s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.data_bucket.arn
}

output "aws_s3_cmek_arn" {
  description = "ARN of the S3 CMEK"
  value       = aws_kms_key.s3_cmek.arn
}

output "aws_glue_catalog_cmek_arn" {
  description = "ARN of the Glue Catalog CMEK"
  value       = aws_kms_key.glue_catalog_cmek.arn
}

output "aws_glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.main.name
}

output "aws_glue_database_arn" {
  description = "ARN of the Glue database"
  value       = aws_glue_catalog_database.main.arn
}

output "aws_storage_transfer_role_arn" {
  description = "ARN of the Storage Transfer role"
  value       = aws_iam_role.storage_transfer_role.arn
}

output "aws_bigquery_omni_role_arn" {
  description = "ARN of the BigQuery Omni role"
  value       = aws_iam_role.bigquery_omni_role.arn
}

output "gcp_gcs_bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.data_bucket.name
}

output "gcp_gcs_cmek_name" {
  description = "Name of the GCS CMEK"
  value       = google_kms_crypto_key.gcs_cmek.name
}

output "bigquery_omni_connection_name" {
  description = "Name of the BigQuery Omni connection"
  value       = google_bigquery_connection.aws_omni.name
}

output "bigquery_external_dataset_id" {
  description = "ID of the BigQuery external dataset"
  value       = google_bigquery_dataset.external_dataset.dataset_id
}

output "vpc_service_perimeter_name" {
  description = "Name of the VPC Service Perimeter"
  value       = google_access_context_manager_service_perimeter.main.name
}
