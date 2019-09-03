use csegdb;

drop table if exists t2_cmip6_forcings;

create table t2_cmip6_forcings(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` INTEGER,
       `description` VARCHAR(50),
       primary key (id));		

insert into t2_cmip6_forcings (value, description)
values
(1,'Default'),
(2,'Future Scenario');
