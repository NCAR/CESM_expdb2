#!/usr/bin/env perl
#
# parseCMIP6JSON - parse the https://github.com/WCRP-CMIP/CMIP6_CVs/blob/master/CMIP6_experiment_id.json
# JSON file and load it into the t2_cmip6_exps table
#
use strict;
use DBI;
use DBD::mysql;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use JSON qw( decode_json );
use Time::Piece;
use Time::Seconds;

use lib qw(.);
use lib "/var/www/html/csegdb/lib";
use config;
use lib "/var/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;

# set up the logger
use Log::Log4perl;
Log::Log4perl->init("/usr/local/expdb-2.0.0/conf/cmip6-json-log.conf");
my $logger = Log::Log4perl->get_logger();

# set starting vars
my %item;
my $status;
my $count;
my $last_update;
my ($sql, $sth);
my ($sql1, $sth1);

# grab the datafile or exit
my $datafile = param('datafile');
if (!defined($datafile)) {
    die("Specify the CMIP6_experiment_id.json file. Usage parseCMIP6JSON.pl datafile=CMIP6_experiment_id.json");
}

# read the datafile
my $data;
open(my $fh, '<', $datafile) or die "cannot open file $datafile";
{
    local $/;
    $data = <$fh>;
}
close($fh);

# log it
$logger->debug("data = " . $data);

# Get the necessary config vars 
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";
my $jsonObj = JSON->new->allow_nonref;
my $json = $jsonObj->decode($data);

my ($activity_id, $additional_allowed_model_components, $parent_activity_id, $parent_experiment_id, $required_model_components, $sub_experiment_id);
my ($end_year, $experiment, $experiment_id, $min_number_yrs_per_sim, $start_year, $tier);

# loop through the json experiment id elements
foreach my $exp ( keys $json->{'experiment_id'} ) {

    # setup the scalar values first
    $end_year = $dbh->quote($json->{'experiment_id'}->{$exp}->{'end_year'});
    $experiment = $dbh->quote($json->{'experiment_id'}->{$exp}->{'experiment'});
    $experiment_id = $dbh->quote($json->{'experiment_id'}->{$exp}->{'experiment_id'});
    $min_number_yrs_per_sim = $dbh->quote($json->{'experiment_id'}->{$exp}->{'min_number_yrs_per_sim'});
    $start_year = $dbh->quote($json->{'experiment_id'}->{$exp}->{'start_year'});

    # collapse the arrays into a comma separated lists
    $activity_id = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'activity_id'}}));
    $additional_allowed_model_components = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'additional_allowed_model_components'}}));
    $parent_activity_id = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'parent_activity_id'}}));			     
    $parent_experiment_id = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'parent_experiment_id'}}));			     
    $required_model_components = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'required_model_components'}}));			     
    $sub_experiment_id = $dbh->quote(join(',', @{$json->{'experiment_id'}->{$exp}->{'sub_experiment_id'}}));

    # get the experiment id from the t2_cmip6_exps table for this $exp
    $sql = qq(select count(id), id from t2_cmip6_exps where name = '$exp');
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my ($count, $exp_id) = $sth->fetchrow;
    $sth->finish();
    if ($count == 0) {
	print "Error in $sql - no matching experiment found for " . $exp;
	next;
    }
    if ($count > 1) {
	print "Constraint violation with more than one experiment found for " . $exp;
	next;
    }

    # update the record in the t2_cmip6_exps table
    $sql = qq(update t2_cmip6_exps set end_year = $end_year,
              experiment = $experiment,
              experiment_id = $experiment_id,
              min_number_yrs_per_sim = $min_number_yrs_per_sim,
              start_year = $start_year,
              activity_id = $activity_id, 
              additional_allowed_model_components = $additional_allowed_model_components,
              parent_activity_id = $parent_activity_id,
              parent_experiment_id = $parent_experiment_id,
              required_model_components = $required_model_components,
              sub_experiment_id = $sub_experiment_id
              where id = $exp_id);
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish();

}
exit 0;


