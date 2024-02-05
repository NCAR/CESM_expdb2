#!/usr/bin/env perl
#
use warnings;
use strict;
##use CGI qw(:standard);
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::Sendmail qw();
use DBI;
use DBD::mysql;
use Time::localtime;
use HTML::Entities;
##use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
##use CGI::Session qw/-ip-match/;
use Data::FormValidator;
use Template;
use lib qw(.);
use lib "/var/www/html/csegdb/lib";
use config;
##use session;
use user;
use lib "/var/www/html/expdb2.0/lib";
use expdb2_0;

#------
# main 
#------
$ENV{PATH} = '';

##my $req = CGI->new;
my %config = &getconfig;
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

# initialize item hash that stores all the info
my %item = ();

# Check the session, see if it's still valid. This will redirect to login page if needed.
##my ($loggedin, $session) = &checksession($req);
##my $cookie = $req->cookie(CGISESSID => $session->id);
##my $sid = $req->cookie('CGISESSID');
# DEBUG
my $loggedin = 1;

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

if($loggedin == 0)
{
    $dbh->disconnect;
##    &sessionexpired;
}
else
{
#
# get the logged in user info and version loaded into the item hash
# note: the current version name and id is read from the config file
#
##    $item{luser_id} = $session->param('user_id');
##    $item{llastname} = $session->param('lastname');
##    $item{lfirstname} = $session->param('firstname');
##    $item{lemail} = $session->param('email');
##    $item{version} = $session->param('version');
##    $item{version_id} = $session->param('version_id');
#DEBUG
    $item{llastname} = 'Bertini';
    $item{lfirstname} = 'Alice';
    $item{lemail} = 'aliceb@ucar.edu';
}
&doActions();

#---------
# end main
#---------
sub doActions()
{
    my $action;
    $action = "showCaseDetail";
##    if (defined $req->param('action'))
##    {
##	$action = $req->param('action');
##    }
##    else
##    {
##	$action = '';
##    }

    if ( length($action) == 0)
    {
	&showExpList;
    }
    if ($action eq "showCMIP6Exps")
    {
	&showCMIP6Exps;
    }
    if ($action eq "showCaseDetail")
    {
##	&showCaseDetail($req->param('case_id'));
	&showCaseDetail(1);
    }
    if ($action eq "expUpdate")
    {
    	&expUpdate();
    }
    if ($action eq "reserveCase")
    {
    	&reserveCase();
    }
}

#------------------
# showExpList - should always default to the CMIP6 experiments
#------------------

sub showExpList
{
    my @CMIP6Exps  = getCMIP6Experiments($dbh);
    my @CMIP6MIPs  = getCMIP6MIPs($dbh);
    my @CMIP6DECKs = getCMIP6DECKs($dbh);
    my @cesm2exps  = getCasesByType($dbh, 2);
    my @projectA   = getCasesByType($dbh, 3);
    my @projectB   = getCasesByType($dbh, 4);
    my @allCases   = getAllCases($dbh);
    my @NCARUsers  = getNCARUsers($dbh);

    my $vars = {
	CMIP6Exps  => \@CMIP6Exps,
	CMIP6MIPs  => \@CMIP6MIPs,
	CMIP6DECKs => \@CMIP6DECKs,
	cesm2exps  => \@cesm2exps,
	projectA   => \@projectA,
	projectB   => \@projectB,
	allCases   => \@allCases,
	NCARUsers  => \@NCARUsers,
	authUser   => \%item,
    };
	
##   print $req->header(-cookie=>$cookie);
    my $tmplFile = '../templates/expList.tmpl';

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/includes:/var/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());

}

#------------------
# showExpDetail
#------------------

sub showCaseDetail
{
    my $case_id = shift;
    my ($case, $fields, $status, $project) = getCaseByID($dbh, $case_id);
    my @allCases = getAllCases($dbh);
    my %validstatus;
    $validstatus{'validated'} = 1;
    $validstatus{'message'} = '';

    if ($case{'case_id'} < 0)
    {
	$validstatus{'validated'} = 0;
	$validstatus{'message'} = 'Error - two or more case records found in database for case ID = $id';
    }
    elsif ($case{'case_id'} == 0)
    {
	$validstatus{'validated'} = 0;
	$validstatus{'message'} = 'Error - no case record found in database for case ID = $id';
    }

    my $vars = {
	case        => $case,
	fields      => $fields,
	status      => $status,
	project     => $project,
	allCases    => \@allCases,
	authUser    => \%item,
	validstatus => \%validstatus,
    };

##    print $req->header(-cookie=>$cookie);
    my $tmplFile = '../templates/expDetail.tmpl';

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/includes:/var/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());

}

sub expUpdate
{
    # TODO update experiment details first check the security against svnuser_id, assign_id, and science_id
    # updates experiment values and returns by displaying expDetail
    # remember this is a POST so exp_id needs to be a hidden input!!
}

sub reserveCase
{
    my ($sql, $sth) = '';
    my ($key, $value) = '';

    my %case;
    my %validstatus;
    $validstatus{'validated'} = 1;
    $validstatus{'message'} = '';

##    foreach $key ( $req->param )  {
##	$item{$key} = ( $req->param( $key ) );
##    }
        
    # check if the casename already exists
    my ($exists, $case_id) = checkCase($dbh, $item{'case'});

    if ($exists) 
    {
	# Error - a casename already exists
	$validstatus{'validated'} = 0;
	$validstatus{'message'} = qq(Error - a case name already exists in the database for case = $item{'case'});
	%case = getCaseByID($dbh, $case_id);
    }
    else
    {
	# reserve the case
	my $case = $dbh->quote($item{'case'});
	$sql = qq(insert into t2_cases (casename, expType_id, is_ens) value ($case, 1, $item{'ensemble'}));
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	# get the case id
	$sql = qq(select id from t2_cases where casename = $case);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my $case_id = $sth->fetchrow();
	$sth->finish();

	# insert notes
	my $note = $dbh->quote($item{'notes'});
	if (length($note) > 0)
	{
	    $sql = qq(insert into t2e_notes (case_id, note, last_update) value ($case_id, $note, NOW()));
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    $sth->finish();
	}

	# update values in the t2j_cmip6 table based on the experiment association
	my $real_num = $dbh->quote($item{'ripf'});
	my $ensemble_size = 0;
	if(($item{'ensemble'} eq 'TRUE') && defined ($item{'ensemble_size'}))
	{
	    $ensemble_size = $item{'ensemble_size'}
	}
	$sql = qq(update t2j_cmip6 set case_id = $case_id,
                  real_num = $real_num, assign_id = $item{'assignUser'},
                  science_id = $item{'scienceUser'}, ensemble_size = $ensemble_size
                  where exp_id = $item{'expName'});
	if ($item{'parentExp'} > 0)
	{
	    $sql = qq(update t2j_cmip6 set case_id = $case_id,
                      real_num = $real_num, assign_id = $item{'assignUser'},
                      science_id = $item{'scienceUser'}, ensemble_size = $ensemble_size,
                      parentExp_id = $item{'parentExp'}
                      where exp_id = $item{'expName'});
	}
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();
	$validstatus{'message'} = 'Success! CMIP6 $case is now reserved.';
	
	# send emails to svnuser login, assign_id and science_id
	my %assignUser = getUserByID($dbh, $item{'assignUser'});
	my %scienceUser = getUserByID($dbh, $item{'scienceUser'});

	my $msgbody = <<EOF;
$item{lfirstname} $item{llastname} has reserved a CMIP6 casename in the CESM Experiments 2.0 Database.
Please follow this link to review the submission.

http://csegweb.cgd.ucar.edu/expdb2.0 

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case name, $case, to review. 

This email is generated automatically by the Experiment Database. 
Replying to this email will go to $item{lfirstname} $item{llastname}.
EOF

        my $email = Email::Simple->create(
	    header => [
		From => $item{lemail},
		To   => "$item{lemail} $assignUser{'email'} $scienceUser{'email'}",
##		To   => "aliceb\@ucar.edu",
		Subject => "New CMIP6 experiment $case has been reserved in the CESM Experiments 2.0 Database",
	    ],
	    body => $msgbody,
	);

	sendmail($email, 
		 { from => $item{lemail},
		   transport => Email::Sender::Transport::Sendmail->new}
	    ) or die "can't send email!";

	%case = getCaseByID($dbh, $case_id);
    }

    # jump the experiment detail screen
    my @allCases = getAllCases($dbh);
    my $vars = {
	case        => \%case,
	allCases    => \@allCases,
	authUser    => \%item,
	validstatus => \%validstatus,
    };

##    print $req->header(-cookie=>$cookie);
    my $tmplFile = '../templates/expDetail.tmpl';

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/includes:/var/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());
}

$dbh->disconnect;
exit;
