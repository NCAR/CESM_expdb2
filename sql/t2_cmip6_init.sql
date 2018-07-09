use csegdb;

drop table if exists t2_cmip6_init;

create table t2_cmip6_init(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` INTEGER,
       `description` VARCHAR(50),
       primary key (id));		

insert into t2_cmip6_init (value, description)
values
(1,'DCPP Forecast initialization'),
(2,'DCPP Hindcast initialization');
