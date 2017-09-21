use csegdb;

drop table if exists t2e_fields;

create table t2e_fields(
       `case_id` INTEGER,
       `field_name` VARCHAR(20),
       `field_value` VARCHAR(200),
       `last_update` DATETIME);
