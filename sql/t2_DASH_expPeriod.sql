use csegdb;

drop table if exists t2_DASH_expPeriod;

create table t2_DASH_expPeriod(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       primary key (id));	

insert into t2_DASH_expPeriod (name)
values 
('paleoclimate'),
('pre-industrial'),
('historical'),
('present-day'),
('scenario (future)'),
('other time period');


