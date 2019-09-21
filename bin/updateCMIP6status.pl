#!/usr/bin/env perl
# updateCMIP6status
#
# updated the temporary t2v_cmip6_status table 
# usage : updateCMIP6status.pl
#

##use warnings;
use strict;
##use DBIx::Profile;
use DBI;
use DBD::mysql;
use Time::localtime;
use DateTime::Format::MySQL;
use Array::Utils qw(:all);
use lib "/home/www/html/csegdb/lib";
use config;
use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;

# Get the necessary config vars for the database
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

my ($sql, $sth);
my @CMIP6Status  = getCMIP6Status($dbh);

#
# loop through the CMIP6status array of hashes and update or insert 
# values into the temporary t2v_cmip6_status table
#

foreach my $ref (@CMIP6Status)
{
    # see if an insert or update is required based on the 
    # existence of the case_id in the t2v_cmip6_status table
    $sql = qq(select COUNT(case_id) from t2v_cmip6_status 
                 where case_id = $ref->{'case_id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my ($count) = $sth->fetchrow;
    $sth->finish;
    if ($count == 0) 
    {
	# insert a record
	$sql = qq(insert into t2v_cmip6_status 
                  (case_id, casename, cmip6_exp_uid, conform_code, conform_color, conform_disk_usage, 
                   conform_last_update, conform_model_date, conform_percent_complete, conform_process_time, 
                   expName, pub_code, pub_color, pub_disk_usage, pub_last_update, run_archive_method, run_code, run_color, 
                   run_disk_usage, run_last_update, run_model_cost, run_model_date, run_model_throughput, 
                   run_percent_complete, sta_archive_method, sta_code, sta_color, sta_disk_usage, sta_last_update, 
                   sta_model_date, sta_percent_complete, total_disk_usage, ts_code, ts_color, ts_disk_usage, 
                   ts_last_update, ts_model_date, ts_percent_complete, ts_process_time, last_update,
                   dash_code, dash_color, dash_disk_usage, dash_last_update) 
                  value ($ref->{'case_id'}, "$ref->{'casename'}", "$ref->{'cmip6_exp_uid'}", 
                   "$ref->{'conform_code'}", "$ref->{'conform_color'}", "$ref->{'conform_disk_usage'}", 
                   "$ref->{'conform_last_update'}", "$ref->{'conform_model_date'}", $ref->{'conform_percent_complete'}, 
                   "$ref->{'conform_process_time'}", "$ref->{'expName'}", "$ref->{'pub_code'}", "$ref->{'pub_color'}", "$ref->{'pub_disk_usage'}",
                   "$ref->{'pub_last_update'}", "$ref->{'run_archive_method'}", "$ref->{'run_code'}", 
                   "$ref->{'run_color'}", "$ref->{'run_disk_usage'}", "$ref->{'run_last_update'}", 
                   "$ref->{'run_model_cost'}", "$ref->{'run_model_date'}", "$ref->{'run_model_throughput'}", 
                   $ref->{'run_percent_complete'}, "$ref->{'sta_archive_method'}", "$ref->{'sta_code'}", 
                   "$ref->{'sta_color'}", "$ref->{'sta_disk_usage'}", "$ref->{'sta_last_update'}", 
                   "$ref->{'sta_model_date'}", $ref->{'sta_percent_complete'}, "$ref->{'total_disk_usage'}", 
                   "$ref->{'ts_code'}", "$ref->{'ts_color'}", "$ref->{'ts_disk_usage'}", "$ref->{'ts_last_update'}", 
                   "$ref->{'ts_model_date'}", $ref->{'ts_percent_complete'}, "$ref->{'ts_process_time'}", NOW(),
                   "$ref->{'dash_code'}", "$ref->{'dash_color'}", "$ref->{'dash_disk_usage'}", "$ref->{'dash_last_update'}"));
	$sth = $dbh->prepare($sql);
	$sth->execute() or die $dbh->errstr;
	$sth->finish;
    }
    elsif ($count == 1)
    {
	$sql = qq(update t2v_cmip6_status set
                  casename = "$ref->{'casename'}",
                  cmip6_exp_uid = "$ref->{'cmip6_exp_uid'}",
                  conform_code = "$ref->{'conform_code'}",
                  conform_color = "$ref->{'conform_color'}",
                  conform_disk_usage = "$ref->{'conform_disk_usage'}",
                  conform_last_update = "$ref->{'conform_last_update'}",
                  conform_model_date = "$ref->{'conform_model_date'}",
                  conform_percent_complete = $ref->{'conform_percent_complete'},
                  conform_process_time = "$ref->{'conform_process_time'}",
                  expName = "$ref->{'expName'}",
                  pub_code = "$ref->{'pub_code'}",
                  pub_color = "$ref->{'pub_color'}",
                  pub_disk_usage = "$ref->{'pub_disk_usage'}",
                  pub_last_update = "$ref->{'pub_last_update'}",
                  run_archive_method = "$ref->{'run_archive_method'}",
                  run_code = "$ref->{'run_code'}",
                  run_color = "$ref->{'run_color'}",
                  run_disk_usage = "$ref->{'run_disk_usage'}",
                  run_last_update = "$ref->{'run_last_update'}",
                  run_model_cost = "$ref->{'run_model_cost'}",
                  run_model_date = "$ref->{'run_model_date'}",
                  run_model_throughput = "$ref->{'run_model_throughput'}",
                  run_percent_complete = $ref->{'run_percent_complete'},
                  sta_archive_method = "$ref->{'sta_archive_method'}",
                  sta_code = "$ref->{'sta_code'}",
                  sta_color = "$ref->{'sta_color'}",
                  sta_disk_usage = "$ref->{'sta_disk_usage'}",
                  sta_last_update = "$ref->{'sta_last_update'}",
                  sta_model_date = "$ref->{'sta_model_date'}",
                  sta_percent_complete = $ref->{'sta_percent_complete'},
                  total_disk_usage = "$ref->{'total_disk_usage'}",
                  ts_code = "$ref->{'ts_code'}",
                  ts_color = "$ref->{'ts_color'}",
                  ts_disk_usage = "$ref->{'ts_disk_usage'}",
                  ts_last_update = "$ref->{'ts_last_update'}",
                  ts_model_date = "$ref->{'ts_model_date'}",
                  ts_percent_complete = $ref->{'ts_percent_complete'},
                  ts_process_time = "$ref->{'ts_process_time'}",
                  last_update = NOW(),
                  dash_code = "$ref->{'dash_code'}",
                  dash_color = "$ref->{'dash_color'}",
                  dash_disk_usage = "$ref->{'dash_disk_usage'}",
                  dash_last_update = "$ref->{'dash_last_update'}"
                  where case_id = $ref->{'case_id'});
	##print "update SQL = " . $sql . "\n";
	$sth = $dbh->prepare($sql);
	$sth->execute() or die $dbh->errstr;
	$sth->finish;
    }
}

# make sure to delete any cases that are in the t2v_cmip6_status table but are no longer in the t2_cases table
# this should only be the case if removeCase.pl has been run manually
$sql = qq(delete from t2v_cmip6_status where case_id not in (select id from t2_cases));
$sth = $dbh->prepare($sql);
$sth->execute() or die $dbh->errstr;
$sth->finish;

$dbh->disconnect;

exit 0;
