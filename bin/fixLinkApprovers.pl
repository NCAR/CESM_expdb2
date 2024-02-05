#!/usr/bin/env perl
# fixLinkApprovers.pl
#
# fix the link approver id in t2j_links to match the case assignee
# usage : fixLinkApprovers.pl
#

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

my ($sql1, $sth1);

my $sql = qq(select case_id, assign_id from t2j_cmip6 where case_id is not null order by case_id);
my $sth = $dbh->prepare($sql);
$sth->execute() or die $dbh->errstr;
while(my $ref = $sth->fetchrow_hashref())
{
    $sql1 = qq(update t2j_links set approver_id = $ref->{'assign_id'} where case_id = $ref->{'case_id'});
    $sth1 = $dbh->prepare($sql1);
    $sth1->execute();
    $sth1->finish();
}
$sth->finish();

$dbh->disconnect;

exit 0;
