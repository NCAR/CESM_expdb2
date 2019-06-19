use csegdb;

drop table if exists t2_DASH_expAttributes;

create table t2_DASH_expAttributes(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `short_name` VARCHAR(50),
       `name` VARCHAR(200),
       primary key (id));	

insert into t2_DASH_expAttributes (short_name, name)
values 
('1pctCO2','1%/yr CO2 increase up to 4x'),
('abrupt-4xCO2','Abrupt 4xCO2 simulation'),
('AMIP','AMIP simulations (~1979-2014)'),
('aquaplanet','Aquaplanet simulation'),
('leave-one-out forcing','All forcings on except one'),
('single forcing','All forcings off except one'),
('slab ocean','Slab ocean simulation'),
('WACCM','Whole Atmosphere Community Climate Model');


