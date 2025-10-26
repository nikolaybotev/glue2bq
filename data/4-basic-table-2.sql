CREATE TABLE IF NOT EXISTS basic_table_2 ( `id` string, `temperature` double
)
PARTITIONED BY ( id
)
LOCATION 's3://glue2bq-dev-data-bucket/iceberg/basic_table_2/'
TBLPROPERTIES ( 'table_type'='ICEBERG', 'vacuum_max_snapshot_age_seconds'='60', 'vacuum_max_metadata_files_to_keep'='5'
);

-- Insert sample data into the lets_try_iceberg Iceberg table

INSERT INTO basic_table_2 VALUES
    ('vehicle-001', 22.5),
    ('vehicle-002', 21.3),
    ('vehicle-001', 23.1),
    ('vehicle-003', 19.8),
    ('vehicle-002', 20.5),
    ('vehicle-001', 24.2),
    ('vehicle-004', 18.2),
    ('vehicle-003', 20.1),
    ('vehicle-002', 22.8),
    ('vehicle-001', 25.5);
