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
use JSON qw( decode_json to_json );
use URI::Escape;

use lib qw(.);
use lib "/var/www/html/csegdb/lib";
use config;
use session;
use lib "/var/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;

my $req = CGI->new;

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
if(!$authsuccessful) {
	# problem with the authorization so return a 401 error
	print $req->header('text/html', '401 SVN username/password incorrect!');
	die "401 - Unauthorized";
}

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";
my $jsonObj = JSON->new->allow_nonref;
my $json = $jsonObj->decode($data);

# look at the queryType to determine what needs to be returned
my $queryType = $json->{'queryType'};
if ($queryType eq 'expTypes') {
    my @expTypes = getExpTypes($dbh);
    print $req->header('text/html', '200');
    print to_json(\@expTypes);
}
else {
    my $expType = $json->{'expType'};
    my ($count, $case_id, $expType_id) = checkCase($dbh, $json->{'casename'}, $expType);
    my %case;

    $case{'case_id'} = $case_id;
    
    if ($queryType eq 'checkCaseExists') {
		# return the case_id
		if ($count == 0) {
		    print $req->header('text/html', '500 Case does not exist!');
		    print to_json(\%case);
		}
		else {
		    print $req->header('text/html', '200');
		    print to_json(\%case);
		}
    }
    elsif ($queryType eq 'CMIP6GlobalAtts') {
		my $json = JSON->new->allow_nonref;
		my ($case, $status, $project, $notes, $links, $globalAtts) = getCMIP6CaseByID($dbh, $case_id);
		print $req->header('application/json');
		print to_json($globalAtts);
    }
    else {
		print $req->header('text/html', '501 invalid query type');
		print $req->h1('False');
    }
}
exit 0;


