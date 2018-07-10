use csegdb;

drop table if exists t2_cmip6_exps;

create table t2_cmip6_exps(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(40),
       `description` VARCHAR(1000),
       `uid` VARCHAR(200),
       `design_mip` VARCHAR(20),
       `request_date` DATETIME DEFAULT NULL,
       `dreq_version` VARCHAR(20),
       `DECK_id` integer DEFAULT NULL,
       primary key (id));	
