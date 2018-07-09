use csegdb;

drop table if exists t2_cmip6_sources;

create table t2_cmip6_sources(
       `id` INTEGER AUTO_INCREMENT NOT NULL,
       `name` varchar(16),
       `description` varchar(200),
       primary key(id));
