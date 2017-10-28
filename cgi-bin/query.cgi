#!/usr/bin/env perl
#
# query - accept a query request post and return a JSON 
#
use strict;
use CGI;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use CGI::Session qw/-ip-match/;
use CGI::Carp qw( set_die_handler );
use DBI;
use DBD::mysql;
use JSON qw( decode_json );
use URI::Escape;

use lib qw(.);
use lib "/home/www/html/csegdb/lib";
use config;
use session;
use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;

my $req = CGI->new;

my %item;

# get the username, password and JSON data that has been posted to the form
my $user = uri_unescape($req->param('username'));
my $password = uri_unescape($req->param('password'));
my $data = uri_unescape($req->param('data'));
my $loginType = 'SVN';

##print STDERR '>>> username = ' . $user . '<<<<\n';
##print STDERR '>>> password = ' . $password . '<<<<\n';
##print STDERR '>>> data = ' . $data . '<<<<\n';

# Get the necessary config vars 
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

# check the authentication
my ($authsuccessful, $autherror) = &svn_authenticate($user, $password);
if(!$authsuccessful)
{
# problem with the authorization so return a 401 error
    print $req->header('text/html', '401 SVN username/password incorrect!');
    die "401 - Unauthorized";
}

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";
my $jsonObj = JSON->new->allow_nonref;
my $json = $jsonObj->decode($data);

my $queryType = $json->{'queryType'};

# look at the queryType to determine what needs to be returned
if ($queryType eq 'checkCaseExists') {
    my ($count, $case_id) = checkCase($dbh, $json->{'casename'});

    # return the count value as True or False
    my $returnCode = 'True'; 
    if ($count == 0) {
	$returnCode = 'False';
    }

    print $req->header('text/html', '200');
    print $req->h1($returnCode);
}

exit 0;


