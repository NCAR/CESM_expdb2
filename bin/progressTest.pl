#!/usr/bin/env perl
#
#  progressTest - compute a process complete percentage
#  based on model_date, nyears and run_startdate
#
use strict;
use DBI;
use DBD::mysql;
use lib qw(.);
use Date::Manip;

use lib "/var/www/html/csegdb/lib";
use config;

use lib "/var/www/html/expdb2.0/lib";
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

my $model_date = '0005-01-01.1';
my $nyears = '10';
my $start_date = '0000-01-01';

my @model_year = split(/-/, $model_date);
my @start_year = split(/-/, $start_date);
    
my $percent_complete = (($model_year[0] - $start_year[0] + 0.0)/$nyears) * 100.0;

