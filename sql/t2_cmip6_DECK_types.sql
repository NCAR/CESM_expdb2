use csegdb;

drop table if exists t2_cmip6_DECK_types;

create table t2_cmip6_DECK_types(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_cmip6_DECK_types (name, description)
values ('Historical'  ,'Historical simulation using CMIP6 forcings (1850-2014)'),
       ('Abrupt_4xCO2','Abrupt 4xCO2 run'),
       ('1pctCO2'     ,'1%/yr CO2 increase'),
       ('AMIP'        ,'AMIP simulation (~1979-2014)'),
       ('PI_control'  ,'Pre-industrial control simulation');
