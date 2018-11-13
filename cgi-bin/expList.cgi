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
	&showCaseDetail();
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
	&showCaseDetail();
    }

    # add note 
    if ($action eq "addNoteProc")
    {
	&addNoteProcess();
	&showCaseDetail();
    }

    # update note 
    if ($action eq "updateNoteProc")
    {
	&updateNoteProcess();
	&showCaseDetail();
    }

    # delete note 
    if ($action eq "deleteNoteProc")
    {
	&deleteNoteProcess();
	&showCaseDetail();
    }

    # add link
    if ($action eq "addLinkProc")
    {
	&addLinkProcess();
	&showCaseDetail();
    }

    # update link
    if ($action eq "updateLinkProc")
    {
	&updateLinkProcess();
	&showCaseDetail();
    }

    # delete link
    if ($action eq "deleteLinkProc")
    {
	&deleteLinkProcess();
	&showCaseDetail();
    }

    # send ESGF publish email
    if ($action eq "publishESGFProcess")
    {
	&publishESGFProcess();
	&showCaseDetail();
    }

    # update ESGF status
    if ($action eq "updateESGFProcess")
    {
	&updateESGFProcess();
	&showCaseDetail();
    }
}

#--------------
sub showExpList
#--------------
{
    my $validstatus = shift;

    my @CMIP6Exps     = getCMIP6Experiments($dbh);
    my @CMIP6MIPs     = getCMIP6MIPs($dbh);
    my @CMIP6DECKs    = getCMIP6DECKs($dbh);
    my @CMIP6DCPPs    = getCMIP6DCPPs($dbh);
    my @CMIP6Sources  = getCMIP6Sources($dbh);
    my @CMIP6Status   = getCMIP6Status($dbh);
    my @CMIP6Inits    = getCMIP6Inits($dbh);
    my @CMIP6Physics  = getCMIP6Physics($dbh);
    my @CMIP6Forcings = getCMIP6Forcings($dbh);
    my @CMIP6Diags    = getCMIP6Diags($dbh);

    my @cesm2exps     = getCasesByType($dbh, 2);
    my @projectA      = getCasesByType($dbh, 3);
    my @projectB      = getCasesByType($dbh, 4);
    my @cesm2tune     = getCasesByType($dbh, 5);
    my @allCases      = getAllCases($dbh);
    my @NCARUsers     = getNCARUsers($dbh);
    my @CMIP6Users    = getCMIP6Users($dbh);


    my $vars = {
	CMIP6Exps     => \@CMIP6Exps,
	CMIP6MIPs     => \@CMIP6MIPs,
	CMIP6DECKs    => \@CMIP6DECKs,
	CMIP6DCPPs    => \@CMIP6DCPPs,
	CMIP6Sources  => \@CMIP6Sources,
	CMIP6Status   => \@CMIP6Status,
	CMIP6Inits    => \@CMIP6Inits,
	CMIP6Physics  => \@CMIP6Physics,
	CMIP6Forcings => \@CMIP6Forcings,
	CMIP6Diags    => \@CMIP6Diags,
	CMIP6Users    => \@CMIP6Users,
	cesm2exps     => \@cesm2exps,
	projectA      => \@projectA,
	projectB      => \@projectB,
	cesm2tune     => \@cesm2tune,
	allCases      => \@allCases,
	NCARUsers     => \@NCARUsers,
	authUser      => \%item,
	validstatus   => $validstatus,
    };
	
    print $req->header(-cookie=>$cookie);
    my $tmplFile = '../templates/expList.tmpl';

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/home/www/html/includes:/home/www/html/expdb2.0/templates',
				 });

    $template->process($tmplFile, $vars) || die ("Problem processing $tmplFile, ", $template->error());

}

#------------------
sub showCaseDetail
#------------------
{
    my $case_id = $req->param('case_id');
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
	# START HERE by removing $fields
	($case, $fields, $status, $notes, $links) = getCaseByID($dbh, $case_id);
    }

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
	case        => $case,
	expType     => $expType,
	status      => $status,
	project     => $project,
	notes       => $notes,
	links       => $links,
	globalAtts  => $globalAtts,
	allCases    => \@allCases,
	authUser    => \%item,
	processes   => \@processes,
	linkTypes   => \@linkTypes,
	validstatus => \%validstatus,
    };

    print $req->header(-cookie=>$cookie);
    my $tmplFile = qq(../templates/expDetails.tmpl);

    my $template = Template->new({
	ENCODING => 'utf8',
	RELATIVE => 1,
	INCLUDE_PATH => '/home/www/html/includes:/home/www/html/expdb2.0/templates',
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

    # reserve this CMIP6 case
    if ($validstatus{'status'} == 1)
    {
	# reserve the case
	my $case_name = $dbh->quote($item{'case'});
	my $title = $dbh->quote($item{'case_title'});
	my $startyear = '';
	if ($item{'runtype'} eq 'startup') {
	    $startyear = $dbh->quote($item{'startup_startyear'}); 
	} elsif ($item{'runtype'} eq 'branch') {
	    $startyear = $dbh->quote($item{'branch_startyear'}); 
	} elsif ($item{'runtype'} eq 'hybrid') {
	    $startyear = $dbh->quote($item{'hybrid_startyear'}); 
	}

	$sql = qq(insert into t2_cases (casename, expType_id, is_ens, title,
                  run_type, run_startdate) 
                  value ($case_name, 1, "$item{'ensemble'}", $title,
                  "$item{'runtype'}", $startyear));
	if ($item{'parentExp'} > 0) {
	    my $run_refdate = $dbh->quote($item{'run_refdate'});
	    $sql = qq(insert into t2_cases (casename, expType_id, is_ens, title,
                      run_type, run_startdate, run_refdate)
                      value ($case_name, 1, "$item{'ensemble'}", $title,
                      "$item{'runtype'}", $startyear, $run_refdate));
	}
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
	if(($item{'ensemble'} eq 'true') && defined ($item{'ensemble_size'}))
	{
	    $ensemble_size = $item{'ensemble_size'}
	}
	$sql = qq(update t2j_cmip6 set case_id = $case_id,
                  variant_label = $variant_label, assign_id = $item{'assignUser'},
                  science_id = $item{'scienceUser'}, ensemble_size = $ensemble_size,
                  ensemble_num = 1, nyears = $item{'nyears'},
                  source_type = $source_type, request_date = NOW()
                  where exp_id = $item{'expName'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->finish();
	if ($item{'parentExp'} > 0)
	{
	    $sql = qq(update t2j_cmip6 set 
                      parentExp_id = $item{'parentExp'}
                      where exp_id = $item{'expName'});
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
                       value ($case_id, 1, $ref->{'id'}, NOW()));
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute() or die $dbh->errstr;
	    $sth1->finish();
	}
	$sth->finish();

	$validstatus{'message'} = qq(Success! CMIP6 $case_name is now reserved.<br/>);

	my $subject = "New CMIP6 experiment $case_name has been reserved in the CESM Experiments 2.0 Database";
	my $msgbody = <<EOF;
$item{lfirstname} $item{llastname} has reserved a CMIP6 casename in the CESM Experiments 2.0 Database.
Please follow this link to review the submission.

http://csegweb.cgd.ucar.edu/expdb2.0 

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case name, $case_name, to review. 

This email is generated automatically by the Experiment Database. 
Replying to this email will go to $item{lfirstname} $item{llastname}.
EOF

	# insert ensemble cases
	if ($ensemble_size)
	{
	    my %base;
	    my ($base_name, $base_ext) = split(/\.([^\.]+)$/, $item{'case'});
	    ## $base_name =~ s/^.//;
	    $base_ext = substr $base_ext, 0, -1;

	    # build up the casenames and add entries into the correct tables
	    for (my $i = 2; $i <= $item{'ensemble_size'}; $i++) {
		$variant_label = "r" . $i . "i" . $init_num . "p" . $phys_num . "f" . $force_num;
		$variant_label = $dbh->quote($variant_label);

		my $ext = sprintf("%03d",$i);
		my $ens_casename = $dbh->quote($base_name . "." . $ext);
		$sql = qq(insert into t2_cases (casename, expType_id, is_ens, title,
                          run_type, run_startdate)
                          value ($ens_casename, 1, "$item{'ensemble'}", $title,
                          "$item{'runtype'}", $startyear));
		if ($item{'parentExp'} > 0) {
		    my $run_refdate = $dbh->quote($item{'run_refdate'});
		    $sql = qq(insert into t2_cases (casename, expType_id, is_ens, title, 
                              run_type, run_startdate, run_refdate)
                              value ($ens_casename, 1, "$item{'ensemble'}", $title, 
                              "$item{'runtype'}", $startyear, $run_refdate));
		}
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();

		# get the case id
		my ($count, $ens_case_id, $expType_id) = checkCase($dbh, $base_name . "." . $ext, 'cmip6');

		# insert values in the t2j_cmip6 table based on the first ensemble experiment
		$sql = qq(insert into t2j_cmip6 (case_id, exp_id, deck_id, design_mip_id,
                          parentExp_id, variant_label, ensemble_num, ensemble_size, assign_id,
                          science_id, request_date, source_type, nyears) select
                          $ens_case_id, exp_id, deck_id, design_mip_id,
                          parentExp_id, $variant_label, $i, ensemble_size, assign_id,
                          science_id, request_date, source_type, nyears from t2j_cmip6
                          where case_id = $case_id);
		$sth = $dbh->prepare($sql);
		$sth->execute();
		$sth->finish();

		# insert notes
		if (length($note) > 0)
		{
		    $sql = qq(insert into t2e_notes (case_id, note, last_update) value ($ens_case_id, $note, NOW()));
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

		$subject = "New CMIP6 Ensemble with first member $case_name has been reserved in the CESM Experiments 2.0 Database";
		$msgbody = <<EOF;
$item{lfirstname} $item{llastname} has reserved a CMIP6 DCPP Ensemble in the CESM Experiments 2.0 Database.
Please follow this link to review the submission.

http://csegweb.cgd.ucar.edu/expdb2.0 

1. Login using your CESM SVN developer login OR your UCAS login 
2. Select or click on the unique case names, starting with the first ensemble member $case_name, to review. 

This email is generated automatically by the Experiment Database. 
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
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
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

    # TODO add isCMIP6Publisher to list of authorized users
    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    my ($case, $status, $project, $notes, $links, $globalAtts);

    # TODO branch on expType_id
    if ($expType_id == '1') 
    {
	($case, $status, $project, $notes, $links, $globalAtts) = getCMIP6CaseByID($dbh, $case_id);
    }

    # check current publish status for process_id = 18 (publish_esgf)
    my ($statusCode, $status_id) = getPublishStatus($dbh, $case_id, 18);

    if ($status_id != 5 || $status_id != 2) {
	# check permissions for publication - can only be Gary, Eric, Sheri or Alice
	# TODO add Eric
	if ($item{luser_id} ~~ [98, 334, 190]) {

	    # update the publish to ESGF status - process_id = 18 to status_id = 2 "started"
	    updatePublishStatus($dbh, $case_id, 18, 2);
	    
	    my $subject = qq(CESM EXDB ESGF Publication Notification: $case_id);
	    my $msgbody = <<EOF;
CESM EXDB ESGF Publication Notification
Case_ID: $case_id
Path:  /glade/collections/cdg/cmip6/$case_id
EOF

            my $email = Email::Simple->create(
		header => [
		    From => $item{lemail},
##		    To   => "gateway-publish@ucar.edu",
		    To   => "aliceb\@ucar.edu",
		    Subject => $subject,
		],
		body => $msgbody,
	    );

	    sendmail($email, 
		     { from => $item{lemail},
		       transport => Email::Sender::Transport::Sendmail->new}
		) or die "can't send email!";

	    # refresh the current page
	    $validstatus{'status'} = 1;
	}
	else {
	    $validstatus{'status'} = 0;
	    $validstatus{'message'} .= qq(Permissions Error - Only Eric Nienhouse, Gary Strand, Sheri Mickelson, or Alice Bertini are allowed to publish to ESGF.<br/>);
	}
    }
    else {
	$validstatus{'status'} = 0;
	$validstatus{'message'} .= qq(This experiment data has already been published to ESGF.<br/>);
    }
}


#--------------------
sub updateESGFProcess
#--------------------
{
# TODO - this needs to be flushed out!
    my $case_id = $req->param('case_id');
    my $expType_id = $req->param('expType_id');

    # TODO add isCMIP6Publisher to list of authorized users
    if ($req->param('expType_id') == 1 && !isCMIP6User($dbh, $item{luser_id}) ) {
	$validstatus{'status'} = 0;
	$validstatus{'message'} = qq(Only CMIP6 authorized users are allowed to modify the case details.<br/>);
	return;
    }

    my ($case, $status, $project, $notes, $links, $globalAtts);

    # TODO branch on expType_id
    if ($expType_id == '1') 
    {
	($case, $status, $project, $notes, $links, $globalAtts) = getCMIP6CaseByID($dbh, $case_id);
    }

    # check current publish status for process_id = 18 (publish_esgf)
    my ($statusCode, $status_id) = getPublishStatus($dbh, $case_id, 18);

    # TODO - finish update the approver and process status in the t2j_status table
}

#-----------------
sub addNoteProcess
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
    my $note = $dbh->quote($item{'note'});
    my $sql = qq(insert into t2e_notes (case_id, note, last_update, svnuser_id) 
               value ($case_id, $note, NOW(), $item{luser_id}));
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
                 svnuser_id = $item{luser_id}
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
    my $sql = qq(insert into t2j_links (case_id, process_id, linkType_id, link, description, last_update) 
               value ($case_id, $item{'processName'}, $item{'linkType'}, $link, $description, NOW()));
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
                 process_id = $item{'processName'}, linkType_id = $item{'linkType'}
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


$dbh->disconnect;
exit;
