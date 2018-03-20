use csegdb;

drop table if exists t2_status;

create table t2_status (
  `id` INTEGER AUTO_INCREMENT NOT NULL,
  `code` varchar(20),
  `description` varchar(100),
  `color` varchar(7),
  primary key (id));

insert into t2_status (code,description,color)
       values ('Unknown','process status unknown','#D3D3D3');

insert into t2_status (code,description,color)
       values ('Started','process has started','#00ff00');

insert into t2_status (code,description,color)
       values ('Shutdown','process was shutdown','#ff8000');

insert into t2_status (code,description,color)
       values ('Failed','process failed to complete','#ff0000');

insert into t2_status (code,description,color)
       values ('Succeeded','process completed successfully','#33ffff');
