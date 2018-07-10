use csegdb;

drop table if exists t2_cmip6_DECK_exps;

create table t2_cmip6_DECK_exps(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `CMIP6_DECK_exp` VARCHAR(20),
       `CESM_exp` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_cmip6_DECK_exps (CMIP6_DECK_exp, CESM_exp, description)
values 
('piControl','Control', 'Pre-industrial control simulation'),
('piControl','Control-WACCM', 'Pre-industrial control simulation with WACCM'),
('piControl','Control-high-res', 'Pre-industrial control simulation at high resolution (CESM2 SE 1/4-degree)'),
('1pctCO2','1pctCO2-CESM2-BGC', '1%/yr CO2 increase up to 4x'),
('1pctCO2','1pctCO2-CESM2-WACCM', '1%/yr CO2 increase up to 4x'),
('historical','historical', 'Historical simulation using CMIP6 forcings (1850-2014)'),
('historical','historical-WACCM', 'Historical simulation using CMIP6 and WACCM forcings (1850-2014)'),
('abrupt-4xCO2','4xCO2-CESM2-BGC','Abrupt 4xCO2 run'),
('abrupt-4xCO2','4xCO2-CESM2-WACCM','Abrupt 4xCO2 run'),
('amip','AMIP-CESM2-BGC', 'AMIP simulation (~1979-2014)'),
('amip','AMIP-CESM2-WACCM', 'AMIP simulation (~1979-2014)');

