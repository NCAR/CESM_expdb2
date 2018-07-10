use csegdb;

drop table if exists t2_cmip6_DECK_types;

create table t2_cmip6_DECK_types(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_cmip6_DECK_types (name, description)
values 
('piControl','Pre-industrial control simulations'),
('1pctCO2','1%/yr CO2 increase up to 4x'),
('historical','Historical simulations using CMIP6 forcings (1850-2014)'),
('abrupt-4xCO2','Abrupt 4xCO2 simulations'),
('amip','AMIP simulations (~1979-2014)');


