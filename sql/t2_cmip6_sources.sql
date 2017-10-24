use csegdb;

drop table if exists t2_cmip6_sources;

create table t2_cmip6_sources(
       `id` INTEGER AUTO_INCREMENT NOT NULL,	
       `name` VARCHAR(20),
       `description` VARCHAR(1000),
       primary key (id));	

insert into t2_cmip6_sources (name, description)
values ('AGCM', 'atmospheric general circulation model, including a land model'),
       ('OGCM', 'ocean general circulation model, including a sea-ice model'),
       ('AOGCM', 'atmosphere-ocean global climate model'),
       ('LAND', 'land model but only if run "offline"'),
       ('ISM', 'ice-sheet model, which may be run "offline" or coupled to an AOGCM'),
       ('RAD', 'radiation code but only if run "offline"'),
       ('BGC', 'for a model component that includes a biogeochemical treatment which at the very least accounts for carbon reservoirs and fluxes in the atmosphere, terrestrial biosphere, and ocean; when run coupled to an AOGCM with atmospheric concentration calculated or prescribed, specify "AOGCM BGC"'),
       ('CHEM', 'appears with either AOGCM or AGCM in models that calculate, rather than rely on prescribed concentrations of atmospheric oxidants including at least ozone'),
       ('AER', 'appears with AOGCM and AGCM in models that calculate tropospheric aerosols driven by emission fluxes, rather than relying on prescribed concentrations'),
       ('SLAB', 'a slab-ocean model');

drop table if exists t2j_cmip6_source_types;

create table t2j_cmip6_source_types(
       `parent_source_id` INTEGER NOT NULL,
       `subtype_source_id` INTEGER NOT NULL);

insert into t2j_cmip6_source_types (parent_source_id, subtype_source_id)
values (1,7),(1,9),(1,8),(1,10),
       (3,7),(3,9),(3,8),(3,5);
