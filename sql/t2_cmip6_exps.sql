use csegdb;

drop table if exists t2_cmip6_exps;

create table t2_cmip6_exps(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(40),
       `description` VARCHAR(1000),
       `uid` VARCHAR(200),
       `design_mip` VARCHAR(20),
       `request_date` DATETIME DEFAULT NULL,
       `dreq_version` VARCHAR(20),
       `DECK_id` integer DEFAULT NULL,
       `activity_id` VARCHAR(40),
       `additional_allowed_model_components` VARCHAR(40),
       `end_year` VARCHAR(5),
       `experiment` VARCHAR(1000),
       `experiment_id` VARCHAR(40),
       `min_number_yrs_per_sim` VARCHAR(6),
       `parent_activity_id` VARCHAR(40),
       `parent_experiment_id` VARCHAR(40),
       `required_model_components` VARCHAR(40),
       `start_year` VARCHAR(4),
       `sub_experiment_id` VARCHAR(500),
       `tier` VARCHAR(2),
       primary key (id));	
