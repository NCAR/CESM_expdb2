#!/usr/bin/env perl
# addEnsemble.pl
#
# add additional ensemble members 004 and 005 for b.e21.BWSSP245cmip6.f09_g17.CMIP6-SSP2-4.5-WACCM.001

use warnings;
use strict;
use DBI;
use DBD::mysql;
use lib qw(.);
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 

use lib "/var/www/html/csegdb/lib";
use config;

# Get the necessary config vars for the database
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

my @cases = ('b.e21.BWSSP245cmip6.f09_g17.CMIP6-SSP2-4.5-WACCM.004','b.e21.BWSSP245cmip6.f09_g17.CMIP6-SSP2-4.5-WACCM.005');
	     
my @variant_labels = ('r4i1p1f1', 'r5i1p1f1');
my $title = 'CMIP6 CESM2 future scenario SSP2-4.5, years 2015-2100, with WACCM6 with interactive chemistry (TSMLT1), interactive land (CLM5), coupled ocean (POP2) with biogeochemistry (MARBL), interactive sea ice (CICE5.1), and non-evolving land ice (CISM2.1).';
my ($sql, $sth, $sql1, $sth1, $ensemble_num);

for (my $i=0; $i <= 1; $i++) {
    $sql = qq(insert into t2_cases (casename, expType_id, is_ens, title)
                 value ('$cases[$i]', 1, 'true', '$title'));
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $sql = qq(select id from t2_cases where casename = '$cases[$i]');
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($id) = $sth->fetchrow();
    $sth->finish();

    # insert into t2j_cmip6
    $ensemble_num = $i + 4;
    $sql = qq(insert into t2j_cmip6 (case_id, exp_id, deck_id, design_mip_id, parentExp_id, 
              variant_label, ensemble_num, ensemble_size, assign_id, science_id, request_date,
              source_type, nyears, source_id, branch_method, branch_time_in_parent,
              branch_time_in_child, parentCase_id) value
              ($id, 287, NULL, 27, 280, '$variant_labels[$i]', $ensemble_num, 5, 262, 262, NOW(), 
               'AGCM BGC CHEM AER', 86, 2, 'standard', '735110.0DO', '711385.0DO', NULL));
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    # insert pending entries in the t2j_status table for each ensemble case
    $sql = qq(select id from t2_process);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    while( my $ref = $sth->fetchrow_hashref() ) 
    {
	my $sql1 = qq(insert into t2j_status (case_id, status_id, process_id, last_update)
                      value ($id, 1, $ref->{'id'}, NOW()));
	my $sth1 = $dbh->prepare($sql1);
	$sth1->execute() or die $dbh->errstr;
	$sth1->finish();
    }
}

$dbh->disconnect;

exit 0;
