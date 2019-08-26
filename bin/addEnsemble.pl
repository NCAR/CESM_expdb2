#!/usr/bin/env perl
# addEnsemble.pl
#
# add additional ensemble members 004 and 010 for f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.*

use warnings;
use strict;
use DBI;
use DBD::mysql;
use lib qw(.);
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 

use lib "/home/www/html/csegdb/lib";
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

my @cases = ('f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.004', 'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.005',
	     'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.006', 'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.007',
	     'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.008', 'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.009',
	     'f.e21.FHIST_BGC.f09_f09_mg17.CMIP6-AMIP.010');
my @variant_labels = ('r4i1p1f1', 'r5i1p1f1', 'r6i1p1f1','r7i1p1f1','r8i1p1f1','r9i1p1f1','r10i1p1f1');
my $title = 'CMIP6 CESM2 AMIP hindcast (1950-2014) with interactive land (CLM5), data ocean, prescribed sea ice, and non-evolving land ice (CISM2.1)';
my ($sql, $sth, $sql1, $sth1, $ensemble_num);

for (my $i=0; $i <= 6; $i++) {
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
              ($id, 271, 5, 7, NULL, '$variant_labels[$i]', $ensemble_num, 10, 271, 230, NOW(), 
               'AGCM BGC AER', 64, 1, 'no parent', NULL, '711385.0DO', NULL));
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
