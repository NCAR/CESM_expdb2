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
       ('tuning', 'CESM2 Tuning Experiments','','',''),
       ('C1', 'CESM2 Community Project C1 - Transient Holocene','','',''),
       ('C2', 'CESM2 Community Project C2 - High-resolution ocean (POP) with biogeochemistry (BGC)','','',''),
       ('C3', 'CESM2 Community Project C3 - Subseasonal-to-seasonal (S2S) hindcasts','','',''),
       ('C4', 'CESM2 Community Project C4 - CESM2 with RCP8.5 projections','','',''),
       ('C5', 'CESM2 Community Project C5 - Development of a CESM Arctic Prediction System (CAPS)','','','');




