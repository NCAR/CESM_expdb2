use csegdb;

drop table if exists t2_cmip6_physics;

create table t2_cmip6_physics(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` INTEGER,
       `description` VARCHAR(50),
       primary key (id));		

insert into t2_cmip6_physics (value, description)
values
(1,'CAM6'),
(2,'CAM6-BGC'),
(3,'CAM6-SE'),
(4,'CAM6-WACCM');
