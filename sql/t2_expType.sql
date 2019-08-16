use csegdb;

drop table if exists t2_expType;

create table t2_expType(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       `exp_module` VARCHAR(20),
       `getCaseByID` VARCHAR(20),
       `expDetail_template` VARCHAR(20),
       primary key (id));	

insert into t2_expType (name, description, exp_module, getCaseByID, expDetail_template)
values ('cmip6', 'CMIP6 Experiments','CMIP6','getCMIP6CaseByID','CMIP6.tmpl'),
       ('production', 'CESM2 Production Experiments','','',''),
       ('lens', 'CESM2 Large Ensemble Experiments','','',''),
       ('TBD project', 'CESM2 TBD Project Experiments','','',''),
       ('tuning', 'CESM2 Tuning Experiments','','','');


