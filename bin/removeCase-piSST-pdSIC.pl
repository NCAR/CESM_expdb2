#!/usr/bin/env perl
# removeExp.pl
#
# special version of remove a case from the expdb2.0 database tables
# usage : removeCase-piSST-pdSIC.pl
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

my ($sql, $sth);
my $sql0 = qq(select id from t2_cases where casename like '%piSST-pdSIC%');
my $sth0 = $dbh->prepare($sql0);
$sth0->execute() or die $dbh->errstr;
while (my $ref = $sth0->fetchrow_hashref())
{
    # delete from the t2j_status table
    $sql = qq(delete from t2j_status where case_id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2j_links table
    $sql = qq(delete from t2j_links where case_id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2e_notes
    $sql = qq(delete from t2e_notes where case_id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2e_fields
    $sql = qq(delete from t2e_fields where case_id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2_cases
    $sql = qq(delete from t2_cases where id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;

    # delete from the t2j_cmip6
    $sql = qq(delete from t2j_cmip6 where case_id = $ref->{'id'});
    $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    $sth->finish;
}

$sth0->finish;
$dbh->disconnect;

exit 0;
