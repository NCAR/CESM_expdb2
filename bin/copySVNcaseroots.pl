#!/usr/bin/env perl
# copySVNcaseroots
#
# copy SVN caseroots that have been published to ESGF
# copySVNcaseroots
#

use warnings;
use strict;
##use DBIx::Profile;
use DBI;
use DBD::mysql;
use Time::localtime;
use DateTime::Format::MySQL;
use Array::Utils qw(:all);
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

#
# loop through the casenames who have been published to ESGF
#
my $sql = qq(select c.casename, c.svn_repo_url 
             from t2_cases as c, t2j_status as j
             where c.id = j.case_id and
             j.process_id = 18 and
             j.status_id = 6);
my $sth = $dbh->prepare($sql);
$sth->execute();
my $dest_url;
my $src_url;
my @args;
while (my $ref = $sth->fetchrow_hashref())
{
    $dest_url = qq(https://svn-cesm2-expdb.cgd.ucar.edu/public/$ref->{'casename'});
    $src_url = qq($ref->{'svn_repo_url'}/trunk);
    @args = ("svn", "copy", $src_url, $dest_url, "--message", "copy caseroot trunk to public repo",
	"--username", $config{'expdb2username'}, "--password", $config{'expdb2password'});
    system(@args);
    if ($? == -1) {
        print "failed to execute: $!\n";
    }
    elsif ($? & 127) {
        printf "child died with signal %d, %s coredump\n",
	($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
        printf "child exited with value %d\n", $? >> 8;
    }
}
$sth->finish();

$dbh->disconnect;

exit 0;
