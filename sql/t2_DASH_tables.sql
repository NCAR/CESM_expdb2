use csegdb;

drop table if exists t2_DASH_tables;

create table t2_DASH_tables(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(40),
       `keyword` VARCHAR(40),
       primary key (id));	

insert into t2_DASH_tables (name, keyword)
values 
('t2_DASH_components', 'stand-alone components'),
('t2_DASH_expAttributes', 'experiment attributes'),
('t2_DASH_expPeriod', 'simulation time period'),
('t2_DASH_expType', 'experiment type'),
('t2_DASH_horizontalResolution', 'horizontal resolution'),
('t2_DASH_temporalResolution', 'temporal resolution'),
('t_workingGroup', 'working group');
