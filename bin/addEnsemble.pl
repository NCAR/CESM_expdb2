#!/usr/bin/env perl
# addEnsemble.pl
#
# add additional ensemble members 002 and 003 for b.e21.BHIST.f09_g17.CMIP6-hist-noLu.001

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

# insert pending entries in the t2j_status table for each ensemble case
my $sql = qq(select id from t2_process);
my $sth = $dbh->prepare($sql);
$sth->execute() or die $dbh->errstr;
while( my $ref = $sth->fetchrow_hashref() ) 
{
    my $sql1 = qq(insert into t2j_status (case_id, status_id, process_id, last_update)
               value (1483, 1, $ref->{'id'}, NOW()));
    my $sth1 = $dbh->prepare($sql1);
    $sth1->execute() or die $dbh->errstr;
    $sth1->finish();

    $sql1 = qq(insert into t2j_status (case_id, status_id, process_id, last_update)
               value (1484, 1, $ref->{'id'}, NOW()));
    $sth1 = $dbh->prepare($sql1);
    $sth1->execute() or die $dbh->errstr;
    $sth1->finish();

}
$sth->finish();

$dbh->disconnect;

exit 0;
