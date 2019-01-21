use csegdb;

drop table if exists t2j_cmip6;

create table t2j_cmip6(
       `case_id` INTEGER,
       `exp_id` INTEGER,
       `deck_id` INTEGER,
       `design_mip_id` INTEGER,
       `parentExp_id` INTEGER,
       `variant_label` VARCHAR(20) default 'r0i0p0f0',
       `ensemble_num` INTEGER,
       `ensemble_size` INTEGER,
       `assign_id` INTEGER,
       `science_id` INTEGER,
       `request_date` DATETIME,
       `source_type` VARCHAR(100),
       `nyears` INTEGER,
       `source_id` INTEGER,
       primary key (exp_id, variant_label));




