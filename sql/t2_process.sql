use csegdb;

drop table if exists t2_process;

create table t2_process(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_process (name, description)
values ('case_run','CESM model run'),
       ('case_st_archive', 'CESM short term archiver'), 
       ('timeseries', 'CESM single variable timeseries'),
       ('atm_averages', 'CESM atmosphere averages'),
       ('ice_averages', 'CESM sea-ice averages'),
       ('lnd_averages', 'CESM land averages'),
       ('ocn_averages', 'CESM ocean averages'),
       ('atm_diagnostics', 'CESM atmosphere diagnostics'),
       ('ice_diagnostics', 'CESM sea-ice diagnostics'),
       ('lnd_diagnostics', 'CESM land diagnostics'),
       ('ilamb_diagnostics', 'CESM land ILAMB diagnostics'),
       ('ocn_diagnostics', 'CESM ocean diagnostics'),
       ('iomb_diagnostics', 'CESM ocean IOMB diagnostics'),
       ('atm_regrid', 'CESM atmosphere regridding'),
       ('lnd_regrid', 'CESM land regridding'),
       ('conform', 'CESM CMOR variable'),
       ('publish_esg', 'CESM to ESG publication'),
       ('publish_dset', 'CESM to DSET publication');
