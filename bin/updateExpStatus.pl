#!/usr/bin/env perl
# updateExpStatus
#
# updated the temporary t2v_exp_status table 
# usage : t2v_exp_status
#

use warnings;
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

#
# loop through the case id's and insert or update
# values into the temporary t2v_exp_status table
#
my $sql = qq(select id from t2_cases);
my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $ref = $sth->fetchrow_hashref())
{
    my @fullstats = getProcessStats($dbh, $ref->{'id'}, $process_name);
    foreach my $fs (@fullstats) 
    {
	
    }
}
$sth->finish();

$dbh->disconnect;

exit 0;
