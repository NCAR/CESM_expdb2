use csegdb;

drop table if exists t2_DASH_tables;

create table t2_DASH_tables(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(40),
       primary key (id));	

insert into t2_DASH_tables (name)
values 
('t2_DASH_components'),
('t2_DASH_expAttributes'),
('t2_DASH_expPeriod'),
('t2_DASH_expType'),
('t2_DASH_horizontalResolution'),
('t2_DASH_temporalResolution');
