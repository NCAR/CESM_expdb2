#!/usr/bin/env perl
use warnings;
use strict;
use DBI;
use DBD::mysql;
use Time::localtime;
use HTML::Entities;
use lib qw(.);
use lib "/home/www/html/csegdb/lib";
use config;
use session;
use user;
use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;

my %config = &getconfig;
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

my @CMIP6DECKs = getCMIP6DECKs($dbh);

$dbh->disconnect();

exit;
