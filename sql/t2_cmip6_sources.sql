use csegdb;

drop table if exists t2_cmip6_sources;

create table t2_cmip6_sources(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(1000),
       primary key (id));	

insert into t2_cmip6_sources (name, description)
values ('AGCM', 'atmospheric general circulation model run with prescribed ocean surface conditions and usually a model of the land surface'),
       ('OGCM', 'ocean general circulation model run uncoupled from an AGCM but, usually including a sea-ice model'),
       ('AOGCM', 'coupled atmosphere-ocean global climate model, additionally including explicit representation of at least the land and sea ice'),
       ('LAND', 'Land model run uncoupled from the atmosphere'),
       ('ISM', 'ice-sheet model that includes ice-flow'),
       ('RAD', 'radiation component of an atmospheric model run "offline"'),
       ('BGC', 'biogeochemistry model component that at the very least accounts for carbon reservoirs and fluxes in the atmosphere, terrestrial biosphere, and ocean'),
       ('CHEM', 'chemistry treatment in an atmospheric model that calculates atmospheric oxidant concentrations (including at least ozone), rather than prescribing them'),
       ('AER', 'aerosol treatment in an atmospheric model where concentrations are calculated based on emissions, transformation, and removal processes (rather than being prescribed or omitted entirely)'),
       ('SLAB', 'slab-ocean used with an AGCM in representing the atmosphere-ocean coupled system');

drop table if exists t2j_cmip6_source_types;

create table t2j_cmip6_source_types(
       `parent_source_id` INTEGER NOT NULL,
       `subtype_source_id` INTEGER NOT NULL);

insert into t2j_cmip6_source_types (parent_source_id, subtype_source_id)
values (1,7),(1,9),(1,8),(1,10),
       (3,7),(3,9),(3,8),(3,5);
