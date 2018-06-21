use csegdb;

drop table if exists t2j_links;

create table t2j_links(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `case_id` INTEGER,
       `process_id` INTEGER,
       `linkType_id` INTEGER,
       `link` varchar(512),
       `description` TEXT,
       `last_update` DATETIME,
       `approvalType_id` INTEGER,
       `approver_id` INTEGER,
        PRIMARY KEY (`id`));
