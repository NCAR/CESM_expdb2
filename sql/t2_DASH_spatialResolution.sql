use csegdb;

drop table if exists t2_DASH_spatialResolution;

create table t2_DASH_spatialResolution(
       `case_id` INTEGER,
       `atm_lon` VARCHAR(10),
       `atm_lat` VARCHAR(10),
       `ocn_lon` VARCHAR(10),
       `ocn_lat` VARCHAR(10));

