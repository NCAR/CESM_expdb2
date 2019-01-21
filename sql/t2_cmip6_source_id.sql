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
('CESM2-SE','spectral element dycore, resolution as yet unspecified, but probably ne120'),
('CESM2-FV2','CAM6 2 degree finite volume dycore, to be used for paleo runs, probably');

