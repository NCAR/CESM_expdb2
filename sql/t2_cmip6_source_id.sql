use csegdb;

drop table if exists t2_cmip6_source_id;

create table t2_cmip6_source_id (
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` VARCHAR(50), 
       `description` VARCHAR(200),
       primary key (id));		

insert into t2_cmip6_source_id (value, description)
values
('CESM2','CAM6 1 degree'),
('CESM2-WACCM','WACCM 1 degree'),
('CESM1-3-SE-CAM5-CMIP5','spectral element dycore for high resolution'),
('CESM2-FV2','CAM6 2 degree finite volume dycore'),
('CESM2-WACCM-FV2','WACCM 2 degree finite volume dycore'),
('CESM1-1-CAM5-CMIP5','CAM5 1 degree'),
('CESM1-3-CAM5-SE-CMIP5-HR','CAM5 CMIP5 spectral element dycore for high resolution'),
('CESM1-3-CAM5-SE-CMIP5-LR','CAM5 CMIP5 spectral element dycore for low resolution');

