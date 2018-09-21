use csegdb;

drop table if exists t2j_status;

create table t2j_status(
       `case_id` INTEGER,
       `status_id` INTEGER,
       `process_id` INTEGER,
       `last_update` DATETIME,
       `model_date` VARCHAR(100) NOT NULL DEFAULT '0000-01-01',
       `disk_usage` VARCHAR(20),
       `disk_path` VARCHAR(4096))
       `disk_path` VARCHAR(4096),
       `archive_method` enum('cylc','archive_metadata') DEFAULT NULL)

