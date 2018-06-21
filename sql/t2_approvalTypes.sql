use csegdb;

drop table if exists t2_approvalTypes;

create table t2_approvalTypes(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(200),
       primary key (id));	

insert into t2_process (name, description)
values ('CESM webpage','Post diagnostics to CESM web pages'),
       ('ESGF','Publish datasets to ESGF'),
       ('DSET','Publish metadata to DSET/DASH');
