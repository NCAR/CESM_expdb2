use csegdb;

drop table if exists t2_cmip6_physics;

create table t2_cmip6_physics(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` INTEGER,
       `description` VARCHAR(50),
       primary key (id));		

insert into t2_cmip6_physics (value, description)
values
(1,'CESM2');
