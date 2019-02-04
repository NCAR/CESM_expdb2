#!/usr/bin/env perl
# removeExp.pl
#
# remove a case from the expdb2.0 database tables
# usage : removeCase.pl case=[case_id]
#

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

my $case_id = param('case');

if (!defined($case_id)) { 
    die("No case_id specified. Usage : removeCase.pl case=[case_id]"); 
}
#
# delete from the t2 tables
#
my $sql = qq(select count(id), expType_id from t2_cases where id = $case_id);
my $sth = $dbh->prepare($sql);
$sth->execute() or die $dbh->errstr;
my ($count, $expType_id) = $sth->fetchrow;
$sth->finish;

if ($count > 0) {
    # delete from the t2j_status table
    $sql = qq(delete from t2j_status where case_id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2j_links table
    $sql = qq(delete from t2j_links where case_id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2e_notes
    $sql = qq(delete from t2e_notes where case_id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2e_fields
    $sql = qq(delete from t2e_fields where case_id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2_cases
    $sql = qq(delete from t2_cases where id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    if ($expType_id == 1) {
	# get the record info from the t2j_cmip6 table for updating
	$sql = qq(select IFNULL(exp_id,0) as exp_id, IFNULL(design_mip_id,0) as design_mip_id from t2j_cmip6 where case_id = $case_id);
	$sth = $dbh->prepare($sql);
	$sth->execute() or die $dbh->errstr;
	my ($exp_id, $design_mip_id) = $sth->fetchrow;
	$sth->finish;

	if ($exp_id > 0 && $design_mip_id > 0) {
	    # update the t2j_cmip6 table
	    $sql = qq(update t2j_cmip6 set case_id = NULL, parentExp_id = NULL, variant_label = NULL,
              ensemble_num = NULL, ensemble_size = NULL, assign_id = NULL, science_id = NULL, 
              request_date = NULL, source_type = NULL, nyears = NULL
              where exp_id = $exp_id and design_mip_id = $design_mip_id);
	    $sth = $dbh->prepare($sql);
	    $sth->execute() or die $dbh->errstr;
	    $sth->finish;
	}
    }
}

$dbh->disconnect;

exit 0;
