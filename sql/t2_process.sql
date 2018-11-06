use csegdb;

drop table if exists t2_process;

create table t2_process(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_process (name, description)
values ('case_run','model run'),
       ('case_st_archive', 'short term archiver'), 
       ('timeseries', 'overall single variable timeseries'),
       ('atm_averages', 'atmosphere averages'),
       ('ice_averages', 'sea-ice averages'),
       ('lnd_averages', 'land averages'),
       ('ocn_averages', 'ocean averages'),
       ('atm_diagnostics', 'atmosphere diagnostics'),
       ('ice_diagnostics', 'sea-ice diagnostics'),
       ('lnd_diagnostics', 'land diagnostics'),
       ('ilamb_diagnostics', 'land ILAMB diagnostics'),
       ('ocn_diagnostics', 'ocean diagnostics'),
       ('iomb_diagnostics', 'ocean IOMB diagnostics'),
       ('atm_regrid', 'atmosphere regridding'),
       ('lnd_regrid', 'land regridding'),
       ('iconform', 'initialize conform variables'),
       ('xconform', 'conform variables'),
       ('publish_esgf', 'ESGF publication'),
       ('publish_dash', 'DASH publication'),
       ('publish_cdg', 'Climate Data Guide publication'),
       ('cvdp_diagnostics', 'climate variability diagnostics'),
       ('cmat_diagnostics', 'climate model analysis tool diagnostics'),
       ('ccr_diagnostics', 'climate change research diagnostics'),
       ('atmv_diagnostics', 'atmosphere variability diagnostics');

