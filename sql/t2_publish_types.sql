use csegdb;

drop table if exists t2_publish_types;

create table t2_publish_types(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       `url` VARCHAR(256),
       primary key (id));	

insert into t2_publish_types (name, description, url)
values ('CESM2','Publish to the CESM2 scientifically validated experiments table','/exp2-public/cgi-bin/scientifically-validated-cesm2.cgi'),
       ('ESGF','Publish datasets to ESGF','https://esgf.llnl.gov'),
       ('CDG','Publish datasets to NCAR Climate Data Gateway (formally ESG - Earth System Grid)','https://www.earthsystemgrid.org'),
       ('DSET','Publish metadata to DSET/DASH','https://www2.cisl.ucar.edu/dash'),
       ('Timing','Publish timing data to CESM2 timings table','https://csegweb.cgd.ucar.edu/timing/cgi-bin/timings.cgi');
