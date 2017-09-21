use csegdb;

drop table if exists t2_status;

create table t2_status (
  `id` INTEGER AUTO_INCREMENT NOT NULL,
  `code` varchar(20),
  `description` varchar(100),
  `color` varchar(7),
  primary key (id));

insert into t2_status (code,description,color)
       values ('Pending','process not yet started','#ffff00');

insert into t2_status (code,description,color)
       values ('Complete','process completed','#33ffff');

insert into t2_status (code,description,color)
       values ('Started','process has started','#00ff00');

insert into t2_status (code,description,color)
       values ('Shutdown','process was shutdown','#ff8000');

insert into t2_status (code,description,color)
       values ('Error','process errored','#ff0000');
