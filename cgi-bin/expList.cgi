#!/usr/bin/env perl
#
use warnings;
use strict;
use Cwd;
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
use Log::Log4perl qw(get_logger);
use Log::Log4perl::DataDumper;
use Template;
use lib qw(.);
use lib "/var/www/html/csegdb/lib";
use config;
use session;
use user;
use lib "/var/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;
use DASH;

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
my $expdb2username = $config{'expdb2username'};
my $expdb2password = $config{'expdb2password'};

# set up the git logger
Log::Log4perl->init($config{'git_logger_conf'});
my $git_logger = get_logger();
Log::Log4perl::DataDumper::override($git_logger);

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
##$loggedin = 1;

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
    # DEBUG
##    $item{luser_id} = 334;

    &doActions();
}

#--------------
sub doActions()
#--------------
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

    # call the function corresponding to the requested action
    if ( length($action) == 0)
    {
	&showExpList(\%validstatus);
    }
    if ($action eq "showCaseDetail")
    {
	&showCaseDetail($req->param('case_id'));
    }
    if ($action eq "reserveCase")
    {
	#call different reservation forms for different experiment types
	if ($req->param('expType_id') == 1)
	{
	    &reserveCaseCMIP6();
	}
    }

    # update case title
    if ($action eq "updateTitleProc")
    {
	&updateTitleProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # add note 
    if ($action eq "addNoteProc")
    {
	&addNoteProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # update note 
    if ($action eq "updateNoteProc")
    {
	&updateNoteProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # delete note 
    if ($action eq "deleteNoteProc")
    {
	&deleteNoteProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # add link
    if ($action eq "addLinkProc")
    {
	&addLinkProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # update link
    if ($action eq "updateLinkProc")
    {
	&updateLinkProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # delete link
    if ($action eq "deleteLinkProc")
    {
	&deleteLinkProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # send ESGF publish email
    if ($action eq "publishESGFProcess")
    {
	&publishESGFProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # update ESGF status
    if ($action eq "updateESGFProcess")
    {
	&updateESGFProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # send CDG publish email
    if ($action eq "publishCDGProcess")
    {
	&publishCDGProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # update CDG status
    if ($action eq "updateCDGProcess")
    {
	&updateCDGProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # add DASH keywords
    if ($action eq "addDASHProcess")
    {
	&addDASHProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # send DASH ISO template to github for publication
    if ($action eq "publishDASHProcess")
    {
	&publishDASHProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # reset DASH keywords and status
    if ($action eq "resetDASHProcess")
    {
	&resetDASHProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # update DASH process
    if ($action eq "updateDASHProcess")
    {
	&updateDASHProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # delete DASH process
    if ($action eq "deleteDASHProcess")
    {
	&deleteDASHProcess();
	&showCaseDetail($req->param('case_id'));
    }

    # udpate CMIP6 file global attributes
    if ($action eq "updateGlobalAttsProc" &&
	$req->param('expType_id') == 1)
    {
	&updateGlobalAttsProcess();
	&showCaseDetail($req->param('case_id'));
    }
}

#--------------
sub showExpList
#--------------
{
    my $validstatus = shift;
    print $req->header(-cookie=>$cookie);

##    my @CMIP6Status      = getCMIP6Status($dbh);
    my @CMIP6Status      = getCMIP6StatusFast($dbh);

    my @CMIP6Exps        = getCMIP6Experiments($dbh, '');
    my @CMIP6ParentExps  = getCMIP6Experiments($dbh, 'cmip6');
    my @CMIP6MIPs        = getCMIP6MIPs($dbh);
    my @CMIP6DECKs       = getCMIP6DECKs($dbh);
    my @CMIP6DCPPs       = getCMIP6DCPPs($dbh);
    my @CMIP6Sources     = getCMIP6Sources($dbh);
    my @CMIP6SourceIDs   = getCMIP6SourceIDs($dbh);
    my @CMIP6Inits       = getCMIP6Inits($dbh);
    my @CMIP6Physics     = getCMIP6Physics($dbh);
    my @CMIP6Forcings    = getCMIP6Forcings($dbh);
    my @CMIP6Diags       = getCMIP6Diags($dbh);

    my @cesm2exps        = getCasesByType($dbh, 2);
    my @lensExps         = getCasesByType($dbh, 3);
    my @cesm2tune        = getCasesByType($dbh, 4);
    my @C1               = getCasesByType($dbh, 5);
    my @C2               = getCasesByType($dbh, 6);
    my @C3               = getCasesByType($dbh, 7);
    my @C4               = getCasesByType($dbh, 8);
    my @C5               = getCasesByType($dbh, 9);
    my @allCases         = getAllCases($dbh);
    my @NCARUsers        = getNCARUsers($dbh);
    my @CMIP6Users       = getCMIP6Users($dbh);

    my $vars = {
	CMIP6Exps        => \@CMIP6Exps,
	CMIP6ParentExps  => \@CMIP6ParentExps,
	CMIP6MIPs        => \@CMIP6MIPs,
	CMIP6DECKs       => \@CMIP6DECKs,
	CMIP6DCPPs       => \@CMIP6DCPPs,
	CMIP6Sources     => \@CMIP6Sources,
	CMIP6SourceIDs   => \@CMIP6SourceIDs,
	CMIP6Status      => \@CMIP6Status,
	CMIP6Inits       => \@CMIP6Inits,
	CMIP6Physics     => \@CMIP6Physics,
	CMIP6Forcings    => \@CMIP6Forcings,
	CMIP6Diags       => \@CMIP6Diags,
	CMIP6Users       => \@CMIP6Users,
	cesm2exps        => \@cesm2exps,
	lensExps         => \@lensExps,
	cesm2tune        => \@cesm2tune,
	C1               => \@C1,
	C2               => \@C2,
	C3               => \@C3,
	C4               => \@C4,
	C5               => \@C5,
	allCases         => \@allCases,
	NCARUsers        => \@NCARUsers,
	authUser         => \%item,
	validstatus      => $validstatus,
    };

    my $tmplFile = '../templates/expList.tmpl';

    my $template = Template->new({
	#ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/styles:/var/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());
}

#------------------
sub showCaseDetail
#------------------
{
    my $case_id = shift;
    my ($case, $fields, $status, $project, $notes, $links, $globalAtts);

    my @allCases = getAllCases($dbh);

    # get expType fields for given case_id - include library call and template file
    my $expType = getExpType($dbh, $case_id);

    if (lc($expType->{'name'}) eq 'cmip6') 
    {
	($case, $status, $project, $notes, $links, $globalAtts) = getCMIP6CaseByID($dbh, $case_id);
    }
    else
    {
	($case, $status, $notes, $links) = getCaseByID($dbh, $case_id);
    }

    # get all the DASH publication keyword options
    my @CMIP6Exps             = getCMIP6Experiments($dbh, '');
    my @CMIP6ParentExps       = getCMIP6Experiments($dbh, 'cmip6');
    my @horizontalResolutions = getHorizontalResolutions($dbh);
    my @temporalResolutions   = getTemporalResolutions($dbh);
    my @expAttributes         = getExpAttributes($dbh);
    my @expTypes              = getExpTypes($dbh);
    my @expPeriods            = getExpPeriods($dbh);
    my @components            = getComponents($dbh);
    my @wgs                   = getWorkingGroups($dbh);
    my $DASHFields            = getDASHFields($dbh, $case_id, $case->{'expType_id'}{'value'});

    if ($case->{'case_id'} < 0)
    {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - two or more case records found in database for case ID = $case_id<br/>);
    }
    elsif ($case->{'case_id'} == 0)
    {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - no case record found in database for case ID = $case_id<br/>);
    }

    my @processes = getProcess($dbh);
    my @linkTypes = getLinkTypes($dbh);

    my $vars = {
	case                  => $case,
	expType               => $expType,
	status                => $status,
	project               => $project,
	notes                 => $notes,
	links                 => $links,
	globalAtts            => $globalAtts,
	allCases              => \@allCases,
	authUser              => \%item,
	processes             => \@processes,
	linkTypes             => \@linkTypes,
	validstatus           => \%validstatus,
        horizontalResolutions => \@horizontalResolutions,
        temporalResolutions   => \@temporalResolutions,
        expAttributes         => \@expAttributes,
        expTypes              => \@expTypes,
        expPeriods            => \@expPeriods,
	components            => \@components,
	CMIP6Exps             => \@CMIP6Exps,
	CMIP6ParentExps       => \@CMIP6ParentExps,
	wgs                   => \@wgs,
	DASHFields            => $DASHFields,
    };

    print $req->header(-cookie=>$cookie);
    my $tmplFile = qq(../templates/expDetails.tmpl);

    my $template = Template->new({
	#ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/includes:/var/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());
}

#-------------------
sub reserveCaseCMIP6
#-------------------
{
    my ($sql, $sth) = '';
    my ($sql1, $sth1) = '';
    my ($key, $value) = '';
    my (%scienceUser, %assignUser) = ();
    my @parents;

    foreach $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
        
    # check if the casename already exists
    my ($exists, $case_id, $expType_id) = checkCase($dbh, $item{'case'}, 'cmip6');
    if ($exists) 
    {
	# Error - a casename already exists
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - a CMIP6 case name already exists in the database for case name = $item{'case'}.<br/>);
    }

    # get the user assignments from the pulldown
    if ($item{'assignUser'} > 0) {
	%assignUser = getUserByID($dbh, $item{'assignUser'});
    }
    else {
	# Error - a user must be assigned
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - A valid user must be assigned to this case.<br/>);
    }

    if ($item{'scienceUser'} > 0) {
	%scienceUser = getUserByID($dbh, $item{'scienceUser'});
    }
    else {
	# Error - a science lead must be assigned
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - A valid user must be selected as the science lead for this case.<br/>);
    }

    # check that the expName value id is selected
    if ($item{'expName'} == 0) {
	# Error - a valid CMIP6 experiment name must be selected
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - A valid CMIP6 experiment name must be associated with this case.<br/>);
    }

    # check source types
    my @sources = $req->param( 'source' );
    my ($valid, $source_type) = checkCMIP6Sources($dbh, \@sources);
    if (length $source_type == 0) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - One or more source associations must be checked.<br/>);
    }
    if (!$valid) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Error - One or more source associations are not allowed.<br/>);
    }

    # construct the "ripf" variant_label
    my $real_num = $item{'real_num'};
    my $init_num = $item{'init_num'};
    my $phys_num = $item{'phys_num'};
    my $force_num = $item{'force_num'};
    my $variant_label = "r" . $real_num . "i" . $init_num . "p" . $phys_num . "f" . $force_num;

    # get the model source_id
    my $source_id = $item{'source_id_num'};

    # reserve this CMIP6 case
    if ($validstatus{'status'} == 1)
    {
	# reserve the case
	my $case_name = $dbh->quote($item{'case'});
	my $title = $dbh->quote($item{'case_title'});

	$sql = qq(insert into t2_cases (casename, expType_id, is_ens, title)
                  value ($case_name, 1, "$item{'ensemble'}", $title));
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	# get the case id 
	my ($exists, $case_id, $expType_id) = checkCase($dbh, $item{'case'}, 'cmip6');

	# insert notes
	my $note = $dbh->quote($item{'notes'});
	if (length($note) > 2)
	{
	    $sql = qq(insert into t2e_notes (case_id, note, last_update, svnuser_id) value ($case_id, $note, NOW(), $item{luser_id}));
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    $sth->finish();
	}

	# update values in the t2j_cmip6 table based on the experiment association
	my $variant_label = $dbh->quote($variant_label);
	my $ensemble_size = 0;
	my $nyears = $item{'nyears'};
	if(($item{'ensemble'} eq 'true') && defined ($item{'ensemble_size'}))
	{
	    $ensemble_size = $item{'ensemble_size'};
	    $nyears = $item{'ensemble_years'};
	}
	$sql = qq(update t2j_cmip6 set case_id = $case_id,
                  variant_label = $variant_label, assign_id = $item{'assignUser'},
                  science_id = $item{'scienceUser'}, ensemble_size = $ensemble_size,
                  ensemble_num = 1, nyears = $nyears, 
                  source_type = $source_type, request_date = NOW(),
                  source_id = $source_id
                  where exp_id = $item{'expName'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();
	if (length($item{'parentExp'}) > 0)
	{
	    @parents = split(',', $item{'parentExp'});

	    # get the parentCase_id from $parents[1] casename
	    $sql = qq(select id from t2_cases where casename = '$parents[1]');
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    ($item{'parentCase_id'}) = $sth->fetchrow();
	    $sth->finish();

	    $sql = qq(update t2j_cmip6 set 
                      parentExp_id = $parents[0], 
                      parentCase_id = $item{'parentCase_id'}
                      where exp_id = $item{'expName'});
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    $sth->finish();
	}

	# get the branch variables
	my $branch_method = $dbh->quote($item{'branch_method'});
	my $branch_child = $dbh->quote("0.0DO");
	my $branch_parent = $dbh->quote("0.0DO");
	if (length($item{'branch_time_in_child'}) > 0) 
	{ 
	    $branch_child = $dbh->quote(convertToCMIP6Time($item{'branch_time_in_child'}));
	}
	if ($item{'parentExp'} > 0 && length($item{'branch_time_in_parent'}) > 0)
	{
	    $branch_parent = $dbh->quote(convertToCMIP6Time($item{'branch_time_in_parent'}));
	}

	# update the t2j_cmip6 table with the branch variables
	$sql = qq(update t2j_cmip6 set branch_method = $branch_method,
                  branch_time_in_child = $branch_child, branch_time_in_parent = $branch_parent
                  where exp_id = $item{'expName'}
                  and case_id = $case_id);
	$sth = $dbh->prepare($sql);
	$sth->execute() or die $dbh->errstr;
	$sth->finish();

	# insert pending entries in the t2j_status table for this case
	$sql = qq(select id from t2_process);
	$sth = $dbh->prepare($sql);
	$sth->execute() or die $dbh->errstr;
	while( my $ref = $sth->fetchrow_hashref() ) 
	{
	    $sql1 = qq(insert into t2j_status (case_id, status_id, process_id, last_update)
                       value ($case_id, 1, $ref->{'id'}, NOW()));
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute() or die $dbh->errstr;
	    $sth1->finish();
	}
	$sth->finish();

	$validstatus{'message'} = qq(Success! CMIP6 $case_name is now reserved.<br/>);

	my $subject = "New CMIP6 experiment $case_name has been reserved in the CESM2 Experiments Database";
	my $msgbody = <<EOF;
$item{lfirstname} $item{llastname} has reserved a CMIP6 casename in the CESM2 Experiments Database.
Please follow this link to review the submission.

http://csegweb.cgd.ucar.edu/expdb2.0 

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case name, $case_name, to review. 

This email is generated automatically by the CESM Experiment Database. 
Replying to this email will go to $item{lfirstname} $item{llastname}.
EOF

	# insert ensemble cases
	if ($ensemble_size)
	{
	    my %base;
	    my ($base_name, $base_ext) = split(/\.([^\.]+)$/, $item{'case'});
	    $base_ext = substr $base_ext, 0, -1;

	    # build up the casenames and add entries into the correct tables
	    for (my $i = 2; $i <= $item{'ensemble_size'}; $i++) {
		$variant_label = "r" . $i . "i" . $init_num . "p" . $phys_num . "f" . $force_num;
		$variant_label = $dbh->quote($variant_label);

		my $ext = sprintf("%03d",$i);
		my $ens_casename = $dbh->quote($base_name . "." . $ext);
		$sql = qq(insert into t2_cases (casename, expType_id, is_ens, title)
                          value ($ens_casename, 1, "$item{'ensemble'}", $title));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();

		# get the case id
		my ($count, $ens_case_id, $expType_id) = checkCase($dbh, $base_name . "." . $ext, 'cmip6');

		# insert values in the t2j_cmip6 table based on the first ensemble experiment
		$sql = qq(insert into t2j_cmip6 (case_id, exp_id, deck_id, design_mip_id,
                          parentExp_id, variant_label, ensemble_num, ensemble_size, assign_id,
                          science_id, request_date, source_type, nyears, 
                          branch_method, branch_time_in_child, branch_time_in_parent) select
                          $ens_case_id, exp_id, deck_id, design_mip_id,
                          parentExp_id, $variant_label, $i, ensemble_size, assign_id,
                          science_id, request_date, source_type, nyears,
                          branch_method, branch_time_in_child, branch_time_in_parent 
                          from t2j_cmip6 
                          where case_id = $case_id);
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();

		# insert notes
		if (length($note) > 0)
		{
		    $sql = qq(insert into t2e_notes (case_id, note, last_update, svnuser_id) value ($ens_case_id, $note, NOW(), $item{luser_id}));
		    $sth = $dbh->prepare($sql);
		    $sth->execute();
		    $sth->finish();
		}

		# insert pending entries in the t2j_status table for this case
		$sql = qq(select id from t2_process);
		$sth = $dbh->prepare($sql);
		$sth->execute() or die $dbh->errstr;
		while( my $ref = $sth->fetchrow_hashref() ) 
		{
		    $sql1 = qq(insert into t2j_status (case_id, status_id, process_id, last_update)
                       value ($ens_case_id, 1, $ref->{'id'}, NOW()));
		    $sth1 = $dbh->prepare($sql1);
		    $sth1->execute() or die $dbh->errstr;
		    $sth1->finish();
		}
		$sth->finish();

		$validstatus{'message'} = qq(Success! CMIP6 $case_name is now reserved.<br/>);

		$subject = "New CMIP6 Ensemble with first member $case_name has been reserved in the CESM2 Experiments Database";
		$msgbody = <<EOF;
$item{lfirstname} $item{llastname} has reserved a CMIP6 DCPP Ensemble in the CESM2 Experiments Database.
Please follow this link to review the submission.

http://csegweb.cgd.ucar.edu/expdb2.0 

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case names, starting with the first ensemble member $case_name, to review. 

This email is generated automatically by the CESM Experiment Database. 
Replying to this email will go to $item{lfirstname} $item{llastname}.
EOF
	    }
	}
	
	# send emails to svnuser login, assign_id and science_id
        my $email = Email::Simple->create(
	    header => [
		From => $item{lemail},
		To   => "$item{lemail} $assignUser{'email'} $scienceUser{'email'}",
		Subject => $subject,
	    ],
	    body => $msgbody,
	);

	sendmail($email, 
		 { from => $item{lemail},
		   transport => Email::Sender::Transport::Sendmail->new}
	    ) or die "can't send email!";

	# redirect to case details
	&showCaseDetail($case_id);
    }
    else {
	# redirect back to the expList
	&showExpList(\%validstatus);
    }
}

#----------------------
sub updateTitleProcess
#----------------------
{
    my $case_id = $req->param('case_id');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $title = $dbh->quote($item{'title'});
    my $sql = qq(update t2_cases set title = $title where id = $case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case title updated.<br/>)

}

#----------------------
sub publishESGFProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $pub_ens = $req->param('pub_ensemble_ESGF');
    my ($statusCode, $status_id, $subject, $msgbody, $email);
    my @cases;
    my %case;

    if ($req->param('expType_id') == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Only CMIP6 authorized data managers are allowed to publish case details to the ESGF.<br/>);
	return;
    }

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be published or not
    if ($pub_ens eq "all") {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	# check current publish status for process_id = 18 (publish_esgf)
	($statusCode, $status_id) = getPublishStatus($dbh, $ca->{'case_id'}, 18);

	if ($status_id != 5 || $status_id != 2) {
	    # update the publish to ESGF status - process_id = 18 to status_id = 2 "started"
	    updatePublishStatus($dbh, $ca->{'case_id'}, 18, 2, $item{luser_id}, 0, 0);
	    
	    $subject = qq(CESM EXDB ESGF Publication Notification: $ca->{'case_id'});
	    $msgbody = <<EOF;
CESM EXDB ESGF Publication Notification
Case_ID: $ca->{'case_id'}
Path:  /glade/collections/cdg/cmip6/$ca->{'case_id'}
EOF

            $email = Email::Simple->create(
		header => [
		    From => $item{lemail},
		    To   => "gateway-publish\@ucar.edu",
		    Cc   => $item{lemail},
		    Subject => $subject,
		],
		body => $msgbody,
	    );

	    sendmail($email, 
		     { from => $item{lemail},
		       transport => Email::Sender::Transport::Sendmail->new}
		) or die "publishESGFProcess can't send email!";

	    # refresh the current page
	    $validstatus{'status'} = 1;
	    $validstatus{'message'} .= qq(Email sent to ESGF publishers (case_id = $ca->{'case_id'}).<br/>);
	}
	else {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment data has already been published to ESGF (case_id = $ca->{'case_id'}).<br/>);
	}
    }
}


#--------------------
sub updateESGFProcess
#--------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $pub_ens = $req->param('verify_ensemble_ESGF');
    my $esgf_url = $req->param('esgf_url');
    my $esgf_size = $req->param('esgf_size') * 1000000;
    my @cases;
    my %case;
    my $link;
    my $esgf_link;

    if (!isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Only CMIP6 authorized data managers are allowed to modify the ESGF publication options.<br/>);
	return;
    }

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be marked success or not
    if ($pub_ens eq "all") {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	# check current publish status for process_id = 18 (publish_esgf)
	my ($statusCode, $status_id) = getPublishStatus($dbh, $ca->{'case_id'}, 18);

	if ($status_id == 2) {
	    $validstatus{'status'} = 1;
	    $validstatus{'message'} .= qq(ESGF successfully published and verified (case_id = $ca->{'case_id'}).<br/>);
	    # update or add a link to esgf
	    $link = getLinkByTypeCaseID($dbh, $ca->{'case_id'}, 'publish_esgf', 1);
	    if ($link->{'count'} == 0) {
		# insert a new link into the t2j_links table
		$esgf_link = $dbh->quote($esgf_url);
		$sql = qq(insert into t2j_links (case_id, process_id, linkType_id, link, description, last_update, approver_id) 
                          value ($case_id, 18, 1, $esgf_link, "ESGF experiment data URL", NOW(), $item{luser_id}));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
	    }
	    else {
		# update link in the t2j_links table
		$esgf_link = $dbh->quote($esgf_url);
		$sql = qq(update t2j_links set link = $esgf_link, last_update = NOW()
                          where id = $link->{'link_id'});
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
	    }

	    # copy the last SVN trunk tag to the public repo at https://svn-cesm2-expdb.cgd.ucar.edu/public
	    copySVNtrunkTag($dbh, $case{'casename'}, $expdb2username, $expdb2password, $item{lemail});

	}
	elsif ($status_id == 1) {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment dataset has not yet been published to ESGF (case_id = $ca->{'case_id'}). Select the "Publish Request to ESGF" button to submit a publication request.<br/>);
	}
	else {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment dataset has already been successfully published to ESGF (case_id = $ca->{'case_id'}).<br/>);
	}
    }

    # update the publish to ESGF status - process_id = 18 to status_id = 6 "published"
    if ($validstatus{'status'} == 1) {
	updatePublishStatus($dbh, $case_id, 18, 6, $item{luser_id}, $esgf_size, 0);
    }
}


#----------------------
sub publishCDGProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $pub_ens = $req->param('pub_ensemble_CDG');
    my ($statusCode, $status_id, $subject, $msgbody, $email);
    my @cases;
    my %case;

    if ($expType_id == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(Only CMIP6 authorized data managers are allowed to publish case details to the CDG.<br/>);
	return;
    }

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be published or not
    if ($pub_ens eq "all") {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	# check current publish status for process_id = 20 (publish_cdg)
	my ($statusCode, $status_id) = getPublishStatus($dbh, $ca->{'case_id'}, 20);

	if ($status_id != 5 || $status_id != 2) {
	    # update the publish to CDG status - process_id = 20 to status_id = 2 "started"
	    updatePublishStatus($dbh, $ca->{'case_id'}, 20, 2, $item{luser_id}, 0, 0);
	    my $casename = $ca->{'casename'};
	    
	    my $subject = qq(CESM EXDB CDG Publication Notification: $ca->{'casename'});
	    my $msgbody = <<EOF;
CESM EXDB CDG Publication Notification
Casename: $ca->{'casename'}
Path:  /glade/collections/cdg/$ca->{'casename'}
EOF

            my $email = Email::Simple->create(
		header => [
		    From => $item{lemail},
		    To   => "gateway-publish\@ucar.edu",
		    Cc   => $item{lemail},
		    Subject => $subject,
		],
		body => $msgbody,
	    );

	    sendmail($email, 
		     { from => $item{lemail},
		       transport => Email::Sender::Transport::Sendmail->new}
		) or die "publishCDGProcess send email!";

	    # refresh the current page
	    $validstatus{'status'} = 1;
	    $validstatus{'message'} .= qq(Email sent to CDG data managers (casename = $ca->{'casename'}).<br/>);
	}
	else {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment data has already been published to CDG (casename = $ca->{'casename'}).<br/>);
	}
    }
}


#--------------------
sub updateCDGProcess
#--------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $pub_ens = $req->param('verify_ensemble_CDG');
    my $cdg_url = $req->param('cdg_url');
    my $cdg_size = $req->param('cdg_size') * 1000000;
    my @cases;
    my %case;
    my $link;
    my $cdg_link;

    if (!isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized data managers are allowed to modify the CDG publication options.<br/>);
	return;
    }

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be marked success or not
    if ($pub_ens eq "all") {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	# check current publish status for process_id = 20 (publish_cdg)
	my ($statusCode, $status_id) = getPublishStatus($dbh, $ca->{'case_id'}, 20);

	if ($status_id == 2) {
	    $validstatus{'status'} = 1;
	    $validstatus{'message'} .= qq(CDG successfully published and verified (casename = $ca->{'casename'}).<br/>);
	    # update or add a link to cdg
	    $link = getLinkByTypeCaseID($dbh, $ca->{'case_id'}, 'publish_cdg', 1);
	    if ($link->{'count'} == 0) {
		# insert a new link into the t2j_links table
		$cdg_link = $dbh->quote($cdg_url);
		$sql = qq(insert into t2j_links (case_id, process_id, linkType_id, link, description, last_update, approver_id) 
                          value ($case_id, 20, 1, $cdg_link, "CDG experiment data URL", NOW(), $item{luser_id}));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
	    }
	    else {
		# update link in the t2j_links table
		$cdg_link = $dbh->quote($cdg_url);
		$sql = qq(update t2j_links set link = $cdg_link, last_update = NOW()
                          where id = $link->{'link_id'});
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
	    }

	    # copy the last SVN trunk tag to the public repo at https://svn-cesm2-expdb.cgd.ucar.edu/public
	    copySVNtrunkTag($dbh, $case{'casename'}, $expdb2username, $expdb2password, $item{lemail});
	}
	elsif ($status_id == 1) {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment dataset has not yet been published to CDG (case_id = $ca->{'case_id'}). Select the "Publish Request to CDG" button to submit a publication request.<br/>);
	}
	else {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(This experiment dataset has already been successfully published to CDG (case_id = $ca->{'case_id'}).<br/>);
	}
    }



    # update the publish to CDG status - process_id = 20 to status_id = 6 "Verified"
    if ($validstatus{'status'} == 1) {
	updatePublishStatus($dbh, $case_id, 20, 6, $item{luser_id}, $cdg_size, 0);
    }
}

#-----------------
sub addNoteProcess
#-----------------
{
    my $case_id = $req->param('case_id');
    my $is_public = $req->param('is_public');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $note = $dbh->quote($item{'note'});
    my $sql = qq(insert into t2e_notes (case_id, note, last_update, svnuser_id, is_public) 
               value ($case_id, $note, NOW(), $item{luser_id}, $is_public));
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case note added.<br/>)
}


#---------------------
sub updateNoteProcess
#---------------------
{
    my $note_id = $req->param('note_id');
    my $is_public = $req->param('is_public');
    
    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $note = $dbh->quote($item{'note'});
    my $sql = qq(update t2e_notes set note = $note, last_update = NOW(),
                 svnuser_id = $item{luser_id}, is_public = $is_public
                 where id = $note_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case note updated.<br/>)
}

#---------------------
sub deleteNoteProcess
#---------------------
{
    my $note_id = $req->param('note_id');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $note = $dbh->quote($item{'note'});
    my $sql = qq(delete from t2e_notes where id = $note_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case note deleted.<br/>)
}

#-----------------
sub addLinkProcess
#-----------------
{
    my $case_id = $req->param('case_id');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $link = $dbh->quote($item{'link'});
    my $description = $dbh->quote($item{'description'});
    my $sql = qq(insert into t2j_links (case_id, process_id, linkType_id, link, description, last_update, approver_id) 
               value ($case_id, $item{'processName'}, $item{'linkType'}, $link, $description, NOW(), $item{luser_id}));
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case link added.<br/>)
}

#--------------------
sub updateLinkProcess
#--------------------
{
    my $link_id = $req->param('link_id');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $link = $dbh->quote($item{'link'});
    my $description = $dbh->quote($item{'description'});
    my $sql = qq(update t2j_links set link = $link, description = $description, last_update = NOW(),
                 process_id = $item{'processName'}, linkType_id = $item{'linkType'}, approver_id = $item{luser_id}
                 where id = $link_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case link updated.<br/>)
}

#--------------------
sub deleteLinkProcess
#--------------------
{
    my $link_id = $req->param('link_id');

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    # get all the input params
    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }
    my $sql = qq(delete from t2j_links where id = $link_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(Case link deleted.<br/>)
}


#----------------------
sub addDASHProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $pub_ens = $req->param('pub_ensemble_DASH');
    my $dash_size = $req->param('dash_size') * 1000000;
    my $expType_id = $req->param('expType_id');
    my $update = 0;
    my (@comps, @eas, @eps, @ets, @hrs, @trs, @wgs);
    my %case;
    my @cases;

    if ($expType_id == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized data managers are allowed to modify the DASH publication options for CMIP6 experiments.<br/>);
	return;
    }

    # get the atm lat/lon spatial resolutions
    my $atm_lat = $dbh->quote($req->param('atmlat_spatialResolution'));
    my $atm_lon = $dbh->quote($req->param('atmlon_spatialResolution'));
    my $ocn_lat = $dbh->quote($req->param('ocnlat_spatialResolution'));
    my $ocn_lon = $dbh->quote($req->param('ocnlon_spatialResolution'));

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be marked included in this DASH record
    if ($pub_ens == 1) {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	$sql = qq(insert into t2_DASH_spatialResolution (case_id, atm_lat, atm_lon, ocn_lat, ocn_lon)
                  value ($ca->{'case_id'}, $atm_lat, $atm_lon, $ocn_lat, $ocn_lon));
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	# loop through the components ID's array for t2_DASH_tables ID = 1
	if ($req->param('components')) {
	    if (ref $req->param('components') eq 'ARRAY' ) {
		@comps = $req->param('components');
	    }
	    else {
		push @comps, $req->param('components');
	    }
	    foreach my $comp (@comps) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                          value ($ca->{'case_id'}, 1, $comp));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the expAttributes ID's array for t2_DASH_tables ID = 2
	if ($req->param('expAttributes')) {
	    if (ref $req->param('expAttributes') eq 'ARRAY' ) {
		@eas = $req->param('expAttributes');
	    }
	    else {
		push @eas, $req->param('expAttributes');
	    }
	    foreach my $ea (@eas) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                           value ($ca->{'case_id'}, 2, $ea));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the expPeriod ID's array for t2_DASH_tables ID = 3
	if ($req->param('expPeriods')) {
	    if (ref $req->param('expPeriods') eq 'ARRAY' ) {
		@eps = $req->param('expPeriods');
	    }
	    else {
		push @eps, $req->param('expPeriods');
	    }
	    foreach my $ep (@eps) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                          value ($ca->{'case_id'}, 3, $ep));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the expTypes ID's array for t2_DASH_tables ID = 4
	if ($req->param('expTypes')) {
	    if (ref $req->param('expTypes') eq 'ARRAY' ) {
		@ets = $req->param('expTypes');
	    }
	    else {
		push @ets, $req->param('expTypes');
	    }
	    foreach my $et (@ets) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                           value ($ca->{'case_id'}, 4, $et));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the horizontalResolution ID's array for t2_DASH_tables ID = 5
	if ($req->param('horizontalResolution')) {
	    if (ref $req->param('horizontalResolution') eq 'ARRAY' ) {
		@hrs = $req->param('horizontalResolution');
	    }
	    else {
		push @hrs, $req->param('horizontalResolution');
	    }
	    foreach my $hr (@hrs) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                          value ($ca->{'case_id'}, 5, $hr));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the temporalResolution ID's array for t2_DASH_tables ID = 6
	if ($req->param('temporalResolution')) {
	    if (ref $req->param('temporalResolution') eq 'ARRAY' ) {
		@trs = $req->param('temporalResolution');
	    }
	    else {
		push @trs, $req->param('temporalResolution');
	    }
	    foreach my $tr (@trs) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                          value ($ca->{'case_id'}, 6, $tr));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}

	# loop through the working group (wgs) ID's array for t2_DASH_tables ID = 7
	if ($req->param('wgs')) {
	    if (ref $req->param('wgs') eq 'ARRAY' ) {
		@wgs = $req->param('wgs');
	    }
	    else {
		push @wgs, $req->param('wgs');
	    }
	    foreach my $wg (@wgs) {
		$sql = qq(insert into t2j_DASH (case_id, table_id, keyword_id)
                          value ($ca->{'case_id'}, 7, $wg));
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();
		$update = 1;
	    }
	}
	# update the t2j_status for the publish_dash (process_id = 19) to Started (status_id = 2)
	updatePublishStatus($dbh, $ca->{'case_id'}, 19, 2, $item{luser_id}, $dash_size, $pub_ens);
    }

    if ($update) {
	$validstatus{'status'} = 1;
	$validstatus{'message'} = qq(DASH keywords successfully added. Press the "Preview and Publish to DASH" button to continue.<br/>)
    }
    else {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(No DASH keywords were selected. One or more keywords must be selected to continue.<br/>)
    }
}

#----------------------
sub publishDASHProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $casename = $req->param('casename');
    my ($tmplFile);
    my %case;
    my @cases;
    my $rc;

    if ($expType_id == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized data managers are allowed to modify the DASH publication options for CMIP6 experiments.<br/>);
	return;
    }

    # gather all the required metadata fields
    my $DASHFields = getDASHFields($dbh, $case_id, $expType_id);

    # check to make sure the dataset size > 0 
    if ($DASHFields->{'asset_size_MB'} == 0) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(DASH records require the asset data size in MB. Please enter this value under the "Update Status of CDG" or "Update Status of ESGF" publication options.<br/>);
	return;
    }

    # load up the JSON template file with the DASHFields
    $tmplFile = qq(../templates/dash_json_cesm.tmpl);
    my $vars = {
	DASHFields => $DASHFields,
    };

    my $template = Template->new({
	RELATIVE => 1,
	INCLUDE_PATH => '/var/www/html/includes:/var/www/html/expdb2.0/templates',
				 });
    my $outfile = qq($config{CESM_JSON_records}/$casename.txt);
    $template->process($tmplFile, $vars, $outfile) || die ("Problem processing $tmplFile, ", $template->error());

    # system call to convert JSON to ISO - check the return code length
    my $input = qq($config{'CESM_JSON_records'}/$casename.txt);
    my $output = qq($config{'DASH_ISO_records'}/$casename.xml);
    # this command must be executed from $config{'dset2iso_dir'} 
    my $dir = getcwd;
    chdir $config{'dset2iso_dir'};
    $rc = qx(/usr/bin/python $config{'dset2iso'} < $input > $output 2>&1);
    chdir $dir;
    if ($rc =~ /error/i) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Failed to call system command: "python $config{'dset2iso'} < $input > $output".<br/>Check paths and permissions, correct and press Publish again. Removing intermediate file "$input".<br/>);
	unlink($input);
	return;
    }
    else {
	$validstatus{'status'} = 1;
	$validstatus{'message'} = qq(Successful conversion of JSON to ISO record<br/>);
    }

    # git fetch origin master
    $rc = qx(/usr/bin/git -C $config{'dash_web_git'} fetch --all 2>&1);
    if ($rc =~ /error/i ) {
	$git_logger->debug('****************************');
	$git_logger->debug('** publishDASHProcess : ' . $casename . ' git fetch --all: ' . $rc);
    }
	
    # git reset --hard to the origin/master
    $rc = '';
    $rc = qx(/usr/bin/git -C $config{'dash_web_git'} reset --hard origin/master 2>&1 1>/dev/null);
    if ($rc =~ /error/i) {
	$git_logger->debug('** publishDASHProcess : ' . $casename . ' git reset --hard origin/master: ' . $rc);
    }

    # add the new ISO record to the repo
    $rc = '';
    $rc = qx(/usr/bin/git -C $config{'dash_web_git'} add . 2>&1);
    if ($rc =~ /error/i) {
	$git_logger->debug('** publishDASHProcess: ' . $casename . ' git add . :' . $rc);
    }

    # commit the new ISO record to the repo
    $rc = '';
    $rc = qx(/usr/bin/git -C $config{'dash_web_git'} commit -m "CESM Experiments Database add $casename.xml ISO record" 2>&1);
    if ($rc =~ /error/i) {
	$git_logger->debug('** publishDASHProcess: ' . $casename . ' git commit :' . $rc);
    }

    # git push origin master using the a personal token
    my $originURL = qq(https://$config{'dset_web_login'}:$config{'dset_web_token'}\@github.com/NCAR/$config{'dash_repo'});
    $rc = '';
    $rc = qx(/usr/bin/git -C $config{'dash_web_git'} push $originURL master 2>&1); 
    if ($rc =~ /error/i) {
	$git_logger->debug('** publishDASHProcess: ' . $casename . ' git push ' . $originURL . 'master :' . $output);
	$git_logger->debug('****************************');
    }

    # get the pub ensemble flag
    my $sql = qq(select pub_ens from t2j_status where
              case_id = $case_id and process_id = 19 and status_id = 2
              order by last_update desc limit 1);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($pub_ens) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be marked success or not
    if ($pub_ens == 1) {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    foreach my $ca (@cases) 
    {
	# everything looks good - update the DASH publication (19) status (5) succeded 
	updatePublishStatus($dbh, $ca->{'case_id'}, 19, 5, $item{luser_id}, $DASHFields->{'asset_size_MB'}, $pub_ens);    

	# add a link to the DASH publication in the t2j_links table
	my $description = $dbh->quote('DASH URL - enter search term CESM2 along with any other experiment title keywords or casename');
	my $sql = qq(insert into t2j_links (case_id, process_id, linkType_id, link, description, last_update, approver_id)
                     value ($ca->{'case_id'}, 19, 1, "$config{'dset_web_url'}", $description, NOW(), $item{luser_id}));
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();
    }

    $validstatus{'status'} = 1;
    $validstatus{'message'} .= qq(Successful publication of record to $config{'dset_web_url'});
}

#----------------------
sub resetDASHProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $casename = $req->param('casename');
    my %case;
    my @cases;

    if ($expType_id == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized data managers are allowed to modify the DASH publication options for CMIP6 experiments.<br/>);
	return;
    }
    
    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # get the pub ensemble flag
    $sql = qq(select pub_ens from t2j_status where
              case_id = $case_id and process_id = 19 and status_id = 2
              order by last_update desc limit 1);
    $dbh->prepare($sql);
    $sth->execute();
    my ($pub_ens) = $sth->fetchrow();
    $sth->finish();

    if ($pub_ens == 1) {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    # reset the all the keywords entries by deleting them
    foreach my $ca (@cases) 
    {
	$sql = qq(delete from t2_DASH_spatialResolution where case_id = $ca->{'case_id'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	$sql = qq(delete from t2j_DASH where case_id = $ca->{'case_id'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();
    }

    # reset publish status to unknown
    updatePublishStatus($dbh, $case_id, 19, 1, $item{luser_id}, 0, 0);

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(DASH keywords and publish status reset.<br/>);
}

#----------------------
sub deleteDASHProcess
#----------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $casename = $req->param('casename');
    my %case;
    my @cases;
    my $xmlfile;

    if ($expType_id == 1 && !isCMIP6Publisher($dbh, $item{luser_id}, $case_id)) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized data managers are allowed to modify the DASH publication options for CMIP6 experiments.<br/>);
	return;
    }
    
    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # get the pub ensemble flag
    $sql = qq(select pub_ens from t2j_status where
              case_id = $case_id and process_id = 19 and status_id = 5
              order by last_update desc limit 1);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($pub_ens) = $sth->fetchrow();
    $sth->finish();

    if ($pub_ens == 1) {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    # reset the all the keywords entries by deleting them
    foreach my $ca (@cases) 
    {
	# delete the ISO record from the github repo
	# git fetch origin master
	$xmlfile = $ca->{'casename'} . ".xml";
	my $output = '';
	$output = qx(/usr/bin/git -C $config{'dash_web_git'} fetch --all 2>&1 1>/dev/null);
	if (length($output) > 0) {
	    $git_logger->debug('****************************');
	    $git_logger->debug('** deleteDASHProcess : ' . $xmlfile . ' git fetch --all: ' . $output);
	}
	
	# git reset --hard to the origin/master
	$output = '';
	$output = qx(/usr/bin/git -C $config{'dash_web_git'} reset --hard origin/master 2>&1 1>/dev/null);
	if (length($output) > 0) {
	    $git_logger->debug('** deleteDASHProcess : ' . $xmlfile . ' git reset --hard origin/master: ' . $output);
	}

	# delete the  ISO record from the repo
	$output = '';
	$output = qx(/usr/bin/git -C $config{'dash_web_git'} rm ./cesm_expdb/$xmlfile 2>&1 1>/dev/null);
	if (length($output) > 0) {
	    $git_logger->debug('** deleteDASHProcess : ' . $xmlfile . ' git rm ./cesm_expdb./$xmlfile: ' . $output);
	}

	# commit the removed ISO record to the repo
	$output = '';
	$output = qx(/usr/bin/git -C $config{'dash_web_git'} commit -m "CESM Experiments Database delete $xmlfile ISO record");
	if (length($output) > 0) {
	    $git_logger->debug('** deleteDASHProcess : ' . $xmlfile . ' git commit: ' . $output);
	}

	# git push origin master using the a personal token
	my $originURL = qq(https://$config{'dset_web_login'}:$config{'dset_web_token'}\@github.com/NCAR/$config{'dash_repo'});
	$output = '';	
	$output = qx(/usr/bin/git -C $config{'dash_web_git'} push $originURL master 2>&1 1>/dev/null);
	if (length($output) > 0) {
	    $git_logger->debug('** deleteDASHProcess : ' . $xmlfile . ' git push $originURL master : ' . $output);
	    $git_logger->debug('****************************');
	}

	# delete from the 
	$sql = qq(delete from t2_DASH_spatialResolution where case_id = $ca->{'case_id'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	$sql = qq(delete from t2j_DASH where case_id = $ca->{'case_id'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	# delete the link for this process_id = 19 and case_id
	$sql = qq(delete from t2j_links where case_id = $ca->{'case_id'} and process_id = 19);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();

	# reset publish status to unknown
	updatePublishStatus($dbh, $ca->{'case_id'}, 19, 1, $item{luser_id}, 0, $pub_ens);
    }

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(DASH ISO record deleted; keywords and publish status reset.<br/>);
}

#---------------------------
sub updateGlobalAttsProcess
#---------------------------
{
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');
    my $caseTitle = $req->param('caseTitle');
    my ($branch_child, $branch_parent, $variant_label, $orig_variant_label) = "";
    my ($ens_id, $base_name, $base_ext, $ens_casename, $ext, $real_num, $casename);
    my ($sql1, $sth1);
    my (@cases, @variant_parts, @parents);
    my (%case);
    my (%globalAtts, %project);
    my ($subject, $msgbody, $email);

    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the CMIP6 file global attributes.<br/>);
	return;
    }

    foreach my $key ( $req->param )  {
	$item{$key} = ( $req->param( $key ) );
    }

    # get the ensemble info about the case
    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                 from t2_cases as c, t2j_cmip6 as j 
                 where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    # check if all ensemble members should be updated or not
    if ($item{'update_ensemble_globalAtts'} eq "all") {
	@cases = getEnsembles($dbh, $case_id);
    }
    else {
	$case{'case_id'} = $case_id;
	push (@cases, \%case);
    }

    for my $ca (@cases) 
    {
	# get the variables quoted from the update form
	my $branch_method = $dbh->quote($item{'branch_method'});
	$sql1 =  qq(update t2j_cmip6 set branch_method = $branch_method );
	if (length($item{'branch_time_in_child'}) > 0) 
	{ 
	    $branch_child = $dbh->quote(convertToCMIP6Time($item{'branch_time_in_child'}));
	    $sql1 .= qq(, branch_time_in_child = $branch_child );
	}
	if (length($item{'branch_time_in_parent'}) > 0)
	{
	    $branch_parent = $dbh->quote(convertToCMIP6Time($item{'branch_time_in_parent'}));
	    $sql1 .= qq(, branch_time_in_parent = $branch_parent );
	}
	if (length($item{'variant_label'}) > 0)
	{
	    # be sure to preserve the realization number for this casename
	    $sql = qq(select variant_label from t2j_cmip6 where case_id = $ca->{'case_id'});
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    ($orig_variant_label) = $sth->fetchrow();
	    $sth->finish();

	    $real_num = substr($orig_variant_label, 0, index($orig_variant_label, 'i'));
	    @variant_parts = split('i', $item{'variant_label'});
	    $variant_label = $real_num . "i" . $variant_parts[1];
	    $variant_label = $dbh->quote($variant_label);
	    $sql1 .= qq(, variant_label = $variant_label );
	}

	if (length($item{'parentExp'}) > 0) 
	{
	    @parents = split(',', $item{'parentExp'});

	    # get the parentCase_id from $parents[1] = casename
	    $sql = qq(select id from t2_cases where casename = '$parents[1]');
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    ($item{'parentCase_id'}) = $sth->fetchrow();
	    $sth->finish();

	    $sql1 .= qq(, parentExp_id = $parents[0], parentCase_id = $item{'parentCase_id'} );
	}
	$sql1 .= qq(where case_id = $ca->{'case_id'});

	# update the t2j_cmip6 table with the branch variables
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute() or die $dbh->errstr;
	$sth1->finish();

	# get the globalAttributes for this case_id
	my ($globalAtts, $project) = getCMIP6GlobalFileAtts($dbh, $ca->{'case_id'}, '');

	# send an email with JSON attachment for new global attributes
	my $subject = qq(CMIP6 File Global Attributes Updated in CESM2 Experiments Database for $ca->{'casename'});
	my $msgbody = <<EOF;
$item{lfirstname} $item{llastname} has updated the CMIP6 file global attributes for casename = $ca->{'casename'} (case_id = $ca->{'case_id'}).

These are the updates:
    branch_method         = $globalAtts->{'branch_method'} 
    branch_time_in_child  = $globalAtts->{'branch_time_in_child'} 
    branch_time_in_parent = $globalAtts->{'branch_time_in_parent'} 
    parent_experiment_id  = $globalAtts->{'parent_experiment_id'}
    variant_label         = $globalAtts->{'variant_label'}
    parent_casename       = $parents[1]

Please see the following experiment for more details:

https://csegweb.cgd.ucar.edu/expdb2.0/cgi-bin/expList.cgi?action=showCaseDetail&case_id=$ca->{'case_id'}

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case name, starting with the first ensemble member, to review. 

You can access all the CMIP6 file global attributes output to a JSON file by running the following 
command in the caseroot:

>archive_metadata --user [SVN-user-login] --password --expType CMIP6 --query_cmip6 [casename] db.json --workdir [full-path-to-working-directory]

This email is generated automatically by the CESM Experiment Database. 
Replying to this email will go to $item{lfirstname} $item{llastname}.
EOF
	# send emails to svnuser login, Gary and Sheri
        my $email = Email::Simple->create(
	    header => [
		From => $item{lemail},
		To   => "$item{lemail} mickelso\@ucar.edu strandwg\@ucar.edu",
		Subject => $subject,
	    ],
	    body => $msgbody,
	);

	sendmail($email, 
		 { from => $item{lemail},
		   transport => Email::Sender::Transport::Sendmail->new}
	    ) or die "can't send email!";
    }

    $validstatus{'status'} = 1;
    $validstatus{'message'} = qq(CMIP6 File Global Attributes successfully updated.<br/>);
}

$dbh->disconnect;
exit;
