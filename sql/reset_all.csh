#!/usr/bin/csh

mysql < ./t2_cases.sql
mysql < ./t2_cmip6_DECK_types.sql
mysql < ./t2_cmip6_exps.sql
mysql < ./t2_cmip6_MIP_types.sql
mysql < ./t2e_fields.sql
mysql < ./t2e_notes.sql
mysql < ./t2_expType.sql
mysql < ./t2j_cmip6.sql
mysql < ./t2j_status.sql
mysql < ./t2_process.sql
mysql < ./t2_status.sql
