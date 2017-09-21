use csegdb;

drop table if exists t2j_status;

create table t2j_status(
       `case_id` INTEGER,
       `status_id` INTEGER,
       `process_id` INTEGER,
       `last_update` DATETIME)
