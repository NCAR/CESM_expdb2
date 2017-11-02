use csegdb;

drop table if exists t2j_cmip6;

create table t2j_cmip6(
       `case_id` INTEGER,
       `exp_id` INTEGER,
       `deck_id` INTEGER,
       `design_mip_id` INTEGER,
       `parentExp_id` INTEGER,
       `real_num` VARCHAR(20),
       `ensemble_num` INTEGER,
       `ensemble_size` INTEGER,
       `assign_id` INTEGER,
       `science_id` INTEGER,
       `request_date` DATETIME,
       `source_type` VARCHAR(100),
       `nyears` INTEGER,
       `variant_info` TEXT);



