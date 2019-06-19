use csegdb;

drop table if exists t2_DASH_horizontalResolution;

create table t2_DASH_horizontalResolution(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(100),
       primary key (id));	

insert into t2_DASH_horizontalResolution (name)
values 
('one-degree atmosphere and ocean grids'),
('high-resolution atmosphere grid'),
('high-resolution ocean grid'),
('low-resolution atmosphere grid'),
('low-resolution ocean grid'),
('refined regional mesh');

