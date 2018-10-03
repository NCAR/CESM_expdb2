#!/usr/bin/env perl
#
use warnings;
use strict;
use CGI qw(:standard);
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::Sendmail qw();
use DBI;
use DBD::mysql;
use Time::localtime;
use HTML::Entities;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use CGI::Session qw/-ip-match/;
use Data::FormValidator;
use Template;
use lib qw(.);
use lib "/home/www/html/csegdb/lib";
use config;
use session;
use user;
use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;
##use GCMD;

#------
# main 
#------
$ENV{PATH} = '';

my $req = CGI->new;
my %config = &getconfig;
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

# initialize item hash that stores all auth info
my %item = ();

# initialize validstatus hash for form feedback
my %validstatus;
$validstatus{'status'} = 1;
$validstatus{'message'} = '';

# Check the session, see if it's still valid. This will redirect to login page if needed.
my ($loggedin, $session) = &checksession($req);
my $cookie = $req->cookie(CGISESSID => $session->id);
my $sid = $req->cookie('CGISESSID');
# DEBUG
##my $loggedin = 1;

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

if($loggedin == 0)
{
    $dbh->disconnect;
    &sessionexpired;
}
else
{
#
# get the logged in user info and version loaded into the item hash
# note: the current version name and id is read from the config file
#
    $item{luser_id} = $session->param('user_id');
    $item{llastname} = $session->param('lastname');
    $item{lfirstname} = $session->param('firstname');
    $item{lemail} = $session->param('email');
    $item{version} = $session->param('version');
    $item{version_id} = $session->param('version_id');
#DEBUG
##    $item{llastname} = 'Bertini';
##    $item{lfirstname} = 'Alice';
##    $item{lemail} = 'aliceb@ucar.edu';
}
&doActions();

#---------
# end main
#---------
sub doActions()
{
    # get the action parameter from the URL
    my $action;
    if (defined $req->param('action'))
    {
	$action = $req->param('action');
    }
    else
    {
	$action = '';
    }

    # get the status parameter from the URL
    if (defined $req->param('status')) 
    {
	$validstatus{'status'} = $req->param('status');
    }

    # get the statusMsg parameter from the URL
    if (defined $req->param('statusMsg'))
    {
	$validstatus{'message'} = $req->param('statusMsg');
    }

    if ($action eq "")
    {
	&publishESGF($req->param('case_id'),$req->param('expType_id'));
    }
    elsif ($action eq "publishESGF")
    {
	&publishESGFProcess($req->param('case_id'),$req->param('expType_id'));
    }
    else
    {
	$dbh->disconnect;
	print $req->header(-cookie=>$cookie);
	print qq(<script type="text/javascript">
                            alert('Problem in publishESGF doactions'); 
                            window.close();
                            </script>);
    }
}

#------------------
# publishESGF form
#------------------

sub publishESGF
{
    my $case_id = shift;
    my $expType_id = shift;
    my ($case, $status, $project, $notes, $links, $globalAtts);

    # Check on permissions return validstatus message

    # TODO branch on expType_id
    if ($expType_id == 1) 
    {
	($case, $status, $project, $notes, $links, $globalAtts) = getCMIP6CaseByID($dbh, $case_id);
    }

    # construct the path to the conformed files
    my $path = "/glade/...";

    my $vars = {
	case        => $case,
	path        => $path,
	authUser    => \%item,
	validstatus => \%validstatus,
    };
	
    print $req->header(-cookie=>$cookie);
    my $tmplFile = '../templates/publishESGF.tmpl';

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/home/www/html/includes:/home/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());

}


#------------------
# publishESGFProcess
#------------------

sub publishESGFProcess
{
    my $case_id = shift;

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }

    # TODO generate email to ESGF group

    # refresh the current page
    print $req->header(-cookie=>$cookie);
    $item{message} =  qq(<script type="text/javascript">
                     alert('Case published to ESGF.');
                     window.close();
                     if (window.opener && !window.opener.closed) {
                            window.opener.location.reload();
                        }
                     </script>);
    my $tmplFile = '../templates/message.tmpl';

    my $template = Template->new({
	RELATIVE => 1,
	INCLUDE_PATH => '/home/www/html/includes:/home/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, \%item) || die ("Problem processing $tmplFile, ", $template->error());
}


$dbh->disconnect;
exit;
