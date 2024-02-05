#!/usr/bin/env perl
#
# query - accept a query request post and return a JSON 
#
use strict;
use CGI;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use DBI;
use DBD::mysql;
##use CGI::Session qw/-ip-match/;
##use CGI::Carp qw(set_die_handler );
use JSON qw( decode_json );
use Time::Piece;
use Time::Seconds;

use lib qw(.);
use lib "/var/www/html/csegdb/lib";
use config;
##use session;
use lib "/var/www/html/expdb2.0/lib";
use expdb2_0;

##my $req = CGI->new;

my %item;
my $status;
my $count;
my $last_update;

# get the username, password and JSON data that has been posted to the form
##my $user = $req->param('username');
##my $password = $req->param('password');

my $jsonfile = param('jsonfile');
if (!defined($jsonfile)) { 
    die("No JSON file specified. Usage : query.pl jsonfile=[JSON_filename]"); 
}

##my $loginType = 'SVN';

#print STDERR '>>> username = ' . $user . '<<<<';
#print STDERR '>>> password = ' . $password . '<<<<';

# Get the necessary config vars 
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

# check the authentication
##my ($authsuccessful, $autherror) = &svn_authenticate($user, $password);
##if(!$authsuccessful)
##{
# problem with the authorization so return a 401 error
##    print $req->header('text/html', '401 SVN username/password incorrect!');
##    die "401 - Unauthorized";
##}

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";
my $jsonObj = JSON->new->allow_nonref;

# this will come from the POST for now get it from the jsonfile
my $data;
{
    local $/;
    open my $fh, "<", $jsonfile;
    $data = <$fh>;
    close $fh;
}

my $json = $jsonObj->decode($data);

my $queryType = $json->{'queryType'};
my ($sql, $sth);

# look at the queryType to determine what needs to be returned
if ($queryType eq 'checkCaseExists') {
    my ($count, $case_id) = checkCase($dbh, $json->{'casename'});

    # return the count value as True or False
    my $returnCode = 'True'; 
    if ($count == 0) {
	$returnCode = 'False';
    }

#    print $req->header('text/html', $returnCode);
    print($returnCode);
}

exit 0;


