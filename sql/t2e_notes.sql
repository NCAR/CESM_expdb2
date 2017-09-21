use csegdb;

drop table if exists t2e_notes;

create table t2e_notes(
       `case_id` INTEGER,
       `note` TEXT,
       `last_update` DATETIME);
