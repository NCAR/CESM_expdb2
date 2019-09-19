use csegdb;

drop table if exists t2e_notes;

create table t2e_notes(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `case_id` INTEGER,
       `note` TEXT,
       `last_update` DATETIME,
       `svnuser_id` INTEGER,
       `is_public` BOOLEAN DEFAULT 0,
        PRIMARY KEY (`id`));
