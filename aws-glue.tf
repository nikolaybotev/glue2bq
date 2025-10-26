# AWS Glue Database
resource "aws_glue_catalog_database" "main" {
  name         = "${replace(local.resource_prefix, "-", "_")}_database"
  description  = "Database for Iceberg tables"
  location_uri = "s3://glue2bq-dev-data-bucket/iceberg/"

  catalog_id = data.aws_caller_identity.current.account_id
}
