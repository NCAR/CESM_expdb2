use csegdb;

drop table if exists t2_linkType;

create table t2_linkType(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       primary key (id));	

insert into t2_linkType (name)
values ('URL'),('file_path'),('HPSS'),('DOI');
       
       
       


