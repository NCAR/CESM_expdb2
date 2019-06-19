#!/usr/bin/env perl
# fixConformPath.pl
#
# fix the conform (process_id = 17) disk_path in t2j_status to drop the extra /[case_id]
# usage : fixConformPath.pl
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

my ($sql1, $sth1);

my $sql = qq(select case_id, disk_path from t2j_status where disk_path is not null and process_id = 17);
my $sth = $dbh->prepare($sql);
$sth->execute() or die $dbh->errstr;
while(my $ref = $sth->fetchrow_hashref())
{
    # work on the disk_path to remove the extra /[case_id] at the end of the string if it exists
    my @parts = split /\//, $ref->{'disk_path'};
    my $last = $parts[(scalar(@parts))-1];
    my $next_last = $parts[(scalar(@parts))-2];
    if (($last eq $next_last) && ($last eq $ref->{'case_id'})) {
	my $disk_path = join "/",@parts[0..(scalar(@parts)-2)];
	$sql1 = qq(update t2j_status set disk_path = '$disk_path' where case_id = $ref->{'case_id'} and process_id = 17);
	print "sql1 = " . $sql1 . "\n";
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	$sth1->finish();
    }
}
$sth->finish();

$dbh->disconnect;

exit 0;
