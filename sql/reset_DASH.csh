#!/usr/bin/csh

mysql < ./t2_DASH_components.sql
mysql < ./t2_DASH_expAttributes.sql
mysql < ./t2_DASH_expPeriod.sql
mysql < ./t2_DASH_expType.sql
mysql < ./t2_DASH_horizontalResolution.sql
mysql < ./t2_DASH_temporalResolution.sql
mysql < ./t2_DASH_tables.sql
mysql < ./t2j_DASH.sql



