# AWS Glue Database
resource "aws_glue_catalog_database" "main" {
  name        = "${local.resource_prefix}_database"
  description = "Database for Iceberg tables"
  location_uri = "s3://glue2bq-dev-data-bucket/iceberg/"

  catalog_id = data.aws_caller_identity.current.account_id
}

resource "aws_glue_catalog_database" "main_2" {
  name        = "${replace(local.resource_prefix, "-", "_")}_database_2"
  description = "Database for Iceberg tables"
  location_uri = "s3://glue2bq-dev-data-bucket/iceberg/"

  catalog_id = data.aws_caller_identity.current.account_id
}
