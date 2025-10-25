CREATE TABLE IF NOT EXISTS lets_try_iceberg (
    `id` string,
    `timestamp` timestamp,
    `speed` int,
    `temperature` float,
    `location` struct < lat: float, lng: float >
)
PARTITIONED BY (
    id
)
LOCATION 's3://glue2bq-dev-data-bucket/iceberg/lets_try_iceberg/'
TBLPROPERTIES (
    'table_type'='ICEBERG',
    'vacuum_max_snapshot_age_seconds'='60',
    'vacuum_max_metadata_files_to_keep'='5'
);
