use csegdb;

drop table if exists t2_cmip6_forcings;

create table t2_cmip6_forcings(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `value` INTEGER,
       `description` VARCHAR(50),
       primary key (id));		

insert into t2_cmip6_forcings (value, description)
values
(1,'Natural forcings'),
(10,'Aerosol direct'),
(11,'Anthroprogenic direct'),
(12,'Black carbon'),
(13,'Land change only'),
(14,'Ozone'),
(15,'Sulfate Aerosol'),
(16,'Solar only'),
(17,'Volcanoes'),
(18,'1pctCO2'),
(19,'abrupt-4xCO2');
