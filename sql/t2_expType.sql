use csegdb;

drop table if exists t2_expType;

create table t2_expType(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_expType (name, description)
values ('CMIP6', 'CMIP6 Experiments'),
       ('production', 'CESM2.0 Production Experiments'),
       ('projectA', 'CESM2.0 Project A Experiments'),
       ('projectB', 'CESM2.0 Project B Experiments');


