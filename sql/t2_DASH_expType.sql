use csegdb;

drop table if exists t2_DASH_expType;

create table t2_DASH_expType(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(50),
       primary key (id));	

insert into t2_DASH_expType (name)
values 
('control'),
('transient'),
('equilibrium'),
('sensitivity'),
('other experiment type');

