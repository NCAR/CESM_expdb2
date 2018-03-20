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
       ('timeseries', 'CESM single variable timeseries generator'),
       ('atm_averages', 'CESM atmosphere averages generator'),
       ('ice_averages', 'CESM sea-ice averages generator'),
       ('lnd_averages', 'CESM land averages generator'),
       ('ocn_averages', 'CESM ocean averages generator'),
       ('atm_diagnostics', 'CESM atmosphere diagnostics generator'),
       ('ice_diagnostics', 'CESM sea-ice diagnostics generator'),
       ('lnd_diagnostics', 'CESM land diagnostics generator'),
       ('ilamb_diagnostics', 'CESM land ILAMB diagnostics generator'),
       ('ocn_diagnostics', 'CESM ocean diagnostics generator'),
       ('iomb_diagnostics', 'CESM ocean IOMB diagnostics generator'),
       ('atm_regrid', 'CESM atmosphere regridding generator'),
       ('lnd_regrid', 'CESM land regridding generator'),
       ('conform', 'CESM CMOR variable generator'),
       ('publish_esg', 'CESM to ESG publication'),
       ('publish_dset', 'CESM to DSET publication');
