Create a terraform project with AWS and GCP providers with the following resources:

* An S3 bucket with CMEK
* A CMEK for AWS Glue Catalog Metadata encryption
* Configure the AWS Glue Catalog Metadata encryption to use the CMEK if possible to that through terraform
* A glue database that points to a table in Iceberg format in the S3 bucket
* If necessary for the glue database configuration, create a script that creates the Iceberg table and populates it with a few records with sample dummy data and uploads it to the S3 bucket
* A GCS bucket with CMEK
* A Storage Transfer Job on GCP that reads from the S3 bucket and writes to the GCS bucket.
* An AWS role for the Storage Transfer job above with access to the S3 bucket and the S3 bucket KMS key
* Configure the Storage Transfer job AWS role with the correct AssumeRoleWithWebIdentity trust policy, using terraform and leveraging the Storage Transfer serviceAccounts.get API if that is possible
* A BigQuery Omni Connection to AWS using a dedicated AWS role
* An AWS role for the above BigQuery Omni Connection 
* Configure the AWS role for BigQuery Omni Connection with AssumeRoleWithWebIdentity using the appropriate connection id output of the BigQuery Omni Connection resource
* Configure the AWS role for BigQuery Omni Connection with access to the Glue Database, S3 Bucket and the KMS Keys of the S3 Bucket and Glue Catalog Metadata
* A BigQuery external dataset that uses the BigQuery Omni Connection and references the Glue Database
* A GCP VPC Service Controls Service Perimeter around the GCP project. Create the perimeter in the Organization and cover all GCP APIs including storage, storage transfer and bigquery. Do NOT create any access levels or ingress or egress rules in the perimeter. I will define these manually via the Violations Analyzer in the GCP console later.
