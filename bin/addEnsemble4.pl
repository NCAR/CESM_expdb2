#!/usr/bin/env perl
# addEnsemble.pl
#
# add additional ensemble members 004 and 005 for b.e21.BWSSP534oscmip6.f09_g17.CMIP6-SSP5-3.4OS-WACCM.001

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

my @cases = ('b.e21.B1850cmip6.f09_g17.DAMIP-ssp245-aer.101', 'b.e21.B1850cmip6.f09_g17.DAMIP-ssp245-aer.102', 'b.e21.B1850cmip6.f09_g17.DAMIP-ssp245-aer.103');
#'b.e21.BSSP126cmip6.f09_g17.CMIP6-SSP1-2.6.101', 'b.e21.BSSP126cmip6.f09_g17.CMIP6-SSP1-2.6.102', 'b.e21.BSSP126cmip6.f09_g17.CMIP6-SSP1-2.6.103');
#'b.e21.BSSP245cmip6.f09_g17.CMIP6-SSP2-4.5.101', 'b.e21.BSSP245cmip6.f09_g17.CMIP6-SSP2-4.5.102', 'b.e21.BSSP245cmip6.f09_g17.CMIP6-SSP2-4.5.103');
#'b.e21.BSSP585cmip6.f09_g17.CMIP6-SSP5-8.5.101', 'b.e21.BSSP585cmip6.f09_g17.CMIP6-SSP5-8.5.102', 'b.e21.BSSP585cmip6.f09_g17.CMIP6-SSP5-8.5.103');
#'b.e21.BSSP370cmip6.f09_g17.CMIP6-SSP3-7.0.101', 'b.e21.BSSP370cmip6.f09_g17.CMIP6-SSP3-7.0.102', 'b.e21.BSSP370cmip6.f09_g17.CMIP6-SSP3-7.0.103');

my @variant_labels = ('r101i1p1f1', 'r102i1p1f1', 'r103i1p1f1');
my $title = 'Extension of DAMIP hist-aer simulation to 2020 and possibly to 2100.';
my ($sql, $sth, $sql1, $sth1, $ensemble_num);

for (my $i=0; $i <= 2; $i++) {
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
    $ensemble_num = $i + 101;
    $sql = qq(insert into t2j_cmip6 (case_id, exp_id, deck_id, design_mip_id, parentExp_id, 
              variant_label, ensemble_num, ensemble_size, assign_id, science_id, request_date,
              source_type, nyears, source_id, branch_method, branch_time_in_parent,
              branch_time_in_child, parentCase_id) value
              ($id, 152, NULL, 17, 127, '$variant_labels[$i]', $ensemble_num, 3, 53, 242, NOW(), 
               'AOGCM BGC CHEM AER', 86, 1, 'standard', '0.0DO', '735110.0DO', 1635));
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
