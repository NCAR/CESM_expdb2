use csegdb;

drop table if exists t2_DASH_temporalResolution;

create table t2_DASH_temporalResolution(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       primary key (id));	

insert into t2_DASH_temporalResolution (name)
values 
('Annual'),
('Monthly'),
('Daily'),
('Sub-daily'),
('Hourly'),
('Sub-hourly');

