# AWS Glue Database
resource "aws_glue_catalog_database" "main" {
  name        = "${local.resource_prefix}_database"
  description = "Database for Iceberg tables"

  catalog_id = data.aws_caller_identity.current.account_id
}
