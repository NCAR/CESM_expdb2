use csegdb;

drop table if exists t2_cmip6_MIP_types;

create table t2_cmip6_MIP_types(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       `dreq_version` VARCHAR(20),
       primary key (id));	
