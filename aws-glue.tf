# AWS Glue Database
resource "aws_glue_catalog_database" "main" {
  name        = "${local.resource_prefix}_database"
  description = "Database for Iceberg tables"

  catalog_id = data.aws_caller_identity.current.account_id
}

# AWS Glue Table (Iceberg format)
resource "aws_glue_catalog_table" "iceberg_table" {
  name          = "sample_iceberg_table"
  database_name = aws_glue_catalog_database.main.name
  catalog_id    = data.aws_caller_identity.current.account_id

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "table_type"                = "ICEBERG"
    "metadata_location"         = "s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/sample_table/metadata/"
    "write_data_location"       = "s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/sample_table/data/"
    "write_metadata_location"   = "s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/sample_table/metadata/"
    "format"                    = "iceberg"
    "iceberg.catalog"           = "glue_catalog"
    "iceberg.catalog.glue.id"   = data.aws_caller_identity.current.account_id
    "iceberg.catalog.glue.region" = var.aws_region
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_bucket.bucket}/iceberg/sample_table/"
    input_format  = "org.apache.hadoop.mapred.FileInputFormat"
    output_format = "org.apache.hadoop.mapred.FileOutputFormat"

    ser_de_info {
      name                  = "iceberg-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
    }
  }
}
