use csegdb;

drop table if exists t2_DASH_components;

create table t2_DASH_components(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(256),
       primary key (id));	

insert into t2_DASH_components (name, description)
values 
('CAM','Community Atmosphere Model'),
('CICE','Community Ice CodE'),
('CISM','Community Ice Sheet Model'),
('CLM','Community Land Model'),
('CTSM','Community Terrestrial System Model'),
('MOM','Modular Ocean Model'),
('MOSART','Model for Scale Adaptive River Transport'),
('POP','Parallel Ocean Program'),
('RTM','River Transport Model'),
('WW3','WaveWatch III');
