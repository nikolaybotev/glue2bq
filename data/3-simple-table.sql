CREATE TABLE IF NOT EXISTS simple_table ( `id` string, `timestamp` timestamp, `speed` int, `temperature` float
)
PARTITIONED BY ( id
)
LOCATION 's3://glue2bq-dev-data-bucket/iceberg/simple_table/'
TBLPROPERTIES ( 'table_type'='ICEBERG', 'vacuum_max_snapshot_age_seconds'='60', 'vacuum_max_metadata_files_to_keep'='5'
);

-- Insert sample data into the lets_try_iceberg Iceberg table

INSERT INTO simple_table VALUES
    ('vehicle-001', CAST('2024-01-15 08:30:00' AS TIMESTAMP), 65, 22.5),
    ('vehicle-002', CAST('2024-01-15 08:45:00' AS TIMESTAMP), 55, 21.3),
    ('vehicle-001', CAST('2024-01-15 09:00:00' AS TIMESTAMP), 72, 23.1),
    ('vehicle-003', CAST('2024-01-15 09:15:00' AS TIMESTAMP), 48, 19.8),
    ('vehicle-002', CAST('2024-01-15 09:30:00' AS TIMESTAMP), 60, 20.5),
    ('vehicle-001', CAST('2024-01-15 10:00:00' AS TIMESTAMP), 58, 24.2),
    ('vehicle-004', CAST('2024-01-15 10:15:00' AS TIMESTAMP), 75, 18.2),
    ('vehicle-003', CAST('2024-01-15 10:30:00' AS TIMESTAMP), 52, 20.1),
    ('vehicle-002', CAST('2024-01-15 11:00:00' AS TIMESTAMP), 68, 22.8),
    ('vehicle-001', CAST('2024-01-15 11:30:00' AS TIMESTAMP), 63, 25.5);
