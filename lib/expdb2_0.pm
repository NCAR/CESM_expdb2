package expdb2_0;
use warnings;
use strict;
use DBI;
use DBD::mysql;
use Time::localtime;
use DateTime::Format::MySQL;
use Array::Utils qw(:all);
use vars qw(@ISA @EXPORT);
use Exporter;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use CGI::Session qw/-ip-match/;
use lib "/home/www/html/csegdb/lib";
use config;

@ISA = qw(Exporter);
@EXPORT = qw(getCMIP6Experiments getCMIP6MIPs getCMIP6DECKs getCMIP6DCPPs getCasesByType 
getPerfExperiments getCaseByID getAllCases getNCARUsers checkCase getUserByID getCMIP6Sources 
checkSources getNoteByID getLinkByID getProcess getLinkTypes getCMIP6GlobalAttributes);

sub getCMIP6Experiments
{
    my $dbh = shift;
    my ($sql1, $sth1);
    my @CMIP6Exps;
    my $sql = "select * from t2_cmip6_exps order by name";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %CMIP6Exp;
	$CMIP6Exp{'exp_id'} = $ref->{'id'};
	$CMIP6Exp{'expName'} = $ref->{'name'};
	$CMIP6Exp{'description'} = $ref->{'description'};
	$CMIP6Exp{'cmip6_exp_uid'} = $ref->{'uid'};
	$CMIP6Exp{'designMIP'} = $ref->{'design_mip'};

	$sql1 = qq(select case_id from t2j_cmip6 
                   where case_id is not null and exp_id = $CMIP6Exp{'exp_id'} group by(exp_id));
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	my ($case_id) = $sth1->fetchrow();
	$sth1->finish();

	if (defined $case_id && $case_id > 0)
	{
	    $CMIP6Exp{'case_id'} = $case_id;
	    $sql1 = qq(select casename from t2_cases where id = $CMIP6Exp{'case_id'} and expType_id = 1);
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute();
	    $CMIP6Exp{'casename'} = $sth1->fetchrow();
	    $sth1->finish();
	}

	push(@CMIP6Exps, \%CMIP6Exp);
    }
    $sth->finish();
    return @CMIP6Exps;
}

sub getCMIP6MIPs
{
    my $dbh = shift;
    my @CMIP6MIPs;
    my ($sql1, $sth1);
    my ($sql2, $sth2);
    my $sql = qq(select * from t2_cmip6_MIP_types 
                 where name not in ('DECK','CMIP6','CMIP5','DCPP')
                 order by name);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %CMIP6MIP;
	my @CMIP6Exps = ();
	$CMIP6MIP{'mip_id'} = $ref->{'id'};
	$CMIP6MIP{'name'} = $ref->{'name'};
	$CMIP6MIP{'description'} = $ref->{'description'};
	$sql1 = qq(select j.case_id, j.exp_id, DATE_FORMAT(j.request_date, '%Y-%m-%d') as req_date
                   from t2j_cmip6 as j, t2_cmip6_exps as e
                   where j.exp_id = e.id and
                   e.design_mip = "$ref->{'name'}");
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	while(my $ref1 = $sth1->fetchrow_hashref())
	{
	    $sql2 = qq(select id as exp_id, name, description, uid, design_mip 
                      from t2_cmip6_exps 
                      where id = $ref1->{'exp_id'});
	    if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
	    {
		$sql2 = qq(select e.id as exp_id, e.name, e.description, e.uid, e.design_mip,
                           c.id as case_id, c.casename, DATE_FORMAT(c.archive_date, '%Y-%m-%d') as arc_date 
                           from t2_cmip6_exps as e, t2_cases as c
                           where e.id = $ref1->{'exp_id'}
                           and c.id = $ref1->{'case_id'} 
                           and c.expType_id = 1);
	    }
	    $sth2 = $dbh->prepare($sql2);
	    $sth2->execute();
	    while(my $ref2 = $sth2->fetchrow_hashref())
	    {
		my %CMIP6Exp;
		$CMIP6Exp{'exp_id'} = $ref2->{'exp_id'};
		$CMIP6Exp{'expName'} = $ref2->{'name'};
		$CMIP6Exp{'description'} = $ref2->{'description'};
		$CMIP6Exp{'cmip6_exp_uid'} = $ref2->{'uid'};
		$CMIP6Exp{'designMIP'} = $ref2->{'design_mip'};
		$CMIP6Exp{'case_id'} = '';
		$CMIP6Exp{'casename'} = '';
		$CMIP6Exp{'archive_date'} = '';
		$CMIP6Exp{'request_date'} = '';
		$CMIP6Exp{'status'} = '';

		if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
		{
		    $CMIP6Exp{'case_id'} = $ref2->{'case_id'};
		    $CMIP6Exp{'casename'} = $ref2->{'casename'};
		    $CMIP6Exp{'archive_date'} = $ref2->{'req_date'};
		    $CMIP6Exp{'request_date'} = $ref1->{'req_date'};
		}
		push(@CMIP6Exps, \%CMIP6Exp);
	    }
	    $CMIP6MIP{'exps'} = [@CMIP6Exps];
	    $sth2->finish();
	}
	push(@CMIP6MIPs, \%CMIP6MIP);
	$sth1->finish();
    }
    $sth->finish();
    return @CMIP6MIPs;
}

sub getCMIP6DECKs
{
    my $dbh = shift;
    my @CMIP6DECKs = ();
    my ($sql1, $sth1);
    my ($sql2, $sth2);
    my $sql = qq(select * from t2_cmip6_DECK_types order by name);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %CMIP6DECK;
	my @CMIP6Exps = ();
	$CMIP6DECK{'expid'} = $ref->{'id'};
	$CMIP6DECK{'name'} = $ref->{'name'};
	$CMIP6DECK{'description'} = $ref->{'description'};
	$sql1 = qq(select case_id, exp_id, DATE_FORMAT(request_date, '%Y-%m-%d') as req_date  
                   from t2j_cmip6 where deck_id = $ref->{'id'});
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	while(my $ref1 = $sth1->fetchrow_hashref())
	{
	    $sql2 = qq(select id as exp_id, name, description, uid, design_mip 
                      from t2_cmip6_exps 
                      where id = $ref1->{'exp_id'});
	    if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
	    {
		$sql2 = qq(select e.id as exp_id, e.name, e.description, e.uid, e.design_mip,
                           c.id as case_id, c.casename, DATE_FORMAT(c.archive_date, '%Y-%m-%d') as arc_date
                           from t2_cmip6_exps as e, t2_cases as c
                           where e.id = $ref1->{'exp_id'}
                           and c.id = $ref1->{'case_id'}
                           and c.expType_id = 1);
	    }
	    $sth2 = $dbh->prepare($sql2);
	    $sth2->execute();
	    while(my $ref2 = $sth2->fetchrow_hashref())
	    {
		my %CMIP6Exp;
		$CMIP6Exp{'exp_id'} = $ref2->{'exp_id'};
		$CMIP6Exp{'expName'} = $ref2->{'name'};
		$CMIP6Exp{'description'} = $ref2->{'description'};
		$CMIP6Exp{'cmip6_exp_uid'} = $ref2->{'uid'};
		$CMIP6Exp{'designMIP'} = $ref2->{'design_mip'};
		$CMIP6Exp{'case_id'} = '';
		$CMIP6Exp{'casename'} = '';
		$CMIP6Exp{'archive_date'} = '';
		$CMIP6Exp{'request_date'} = '';
		$CMIP6Exp{'status'} = '';

		if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
		{
		    $CMIP6Exp{'case_id'} = $ref2->{'case_id'};
		    $CMIP6Exp{'casename'} = $ref2->{'casename'};
		    $CMIP6Exp{'archive_date'} = $ref2->{'arc_date'};
		    $CMIP6Exp{'request_date'} = $ref1->{'req_date'};
		}
		push(@CMIP6Exps, \%CMIP6Exp);
	    }
	    $CMIP6DECK{'exps'} = [@CMIP6Exps];
	    $sth2->finish();
	}
	push(@CMIP6DECKs, \%CMIP6DECK);
	$sth1->finish();
    }
    $sth->finish();
    return @CMIP6DECKs;
}


sub getCMIP6DCPPs
{
    my $dbh = shift;
    my @CMIP6DCPPs = ();
    my ($sql1, $sth1);
    my ($sql2, $sth2);

    my $sql = qq(select id from t2_cmip6_MIP_types where name like 'DCPP');
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($DCPPMIPid) = $sth->fetchrow();
    $sth->finish();

    $sql = qq(select * from t2_cmip6_exps where design_mip = 'DCPP' order by name);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %CMIP6DCPP;
	my @DCPPExps = ();
	$CMIP6DCPP{'expid'} = $ref->{'id'};
	$CMIP6DCPP{'name'} = $ref->{'name'};
	$CMIP6DCPP{'description'} = $ref->{'description'};
	$CMIP6DCPP{'uid'} = $ref->{'uid'};
	$sql1 = qq(select case_id, exp_id, ensemble_num, ensemble_size, 
                   DATE_FORMAT(request_date, '%Y-%m-%d') as req_date  
                   from t2j_cmip6 
                   where design_mip_id = $DCPPMIPid
                   and exp_id = $ref->{'id'});
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	while(my $ref1 = $sth1->fetchrow_hashref())
	{
	    $sql2 = qq(select id as exp_id, name, description, uid, design_mip 
                      from t2_cmip6_exps 
                      where id = $ref1->{'exp_id'});
	    if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
	    {
		$sql2 = qq(select e.id as exp_id, e.name, e.description, e.uid, e.design_mip,
                           c.id as case_id, c.casename, DATE_FORMAT(c.archive_date, '%Y-%m-%d') as arc_date
                           from t2_cmip6_exps as e, t2_cases as c
                           where e.id = $ref1->{'exp_id'}
                           and c.id = $ref1->{'case_id'}
                           and c.expType_id = 1);
	    }
	    $sth2 = $dbh->prepare($sql2);
	    $sth2->execute();
	    while(my $ref2 = $sth2->fetchrow_hashref())
	    {
		my %DCPPExp;
		$DCPPExp{'exp_id'} = $ref2->{'exp_id'};
		$DCPPExp{'expName'} = $ref2->{'name'};
		$DCPPExp{'description'} = $ref2->{'description'};
		$DCPPExp{'cmip6_exp_uid'} = $ref2->{'uid'};
		$DCPPExp{'designMIP'} = $ref2->{'design_mip'};
		$DCPPExp{'case_id'} = '';
		$DCPPExp{'casename'} = '';
		$DCPPExp{'archive_date'} = '';
		$DCPPExp{'request_date'} = '';
		$DCPPExp{'status'} = '';

		if (defined $ref1->{'case_id'} && length($ref1->{'case_id'}) > 0)
		{
		    $DCPPExp{'case_id'} = $ref2->{'case_id'};
		    $DCPPExp{'casename'} = $ref2->{'casename'};
		    $DCPPExp{'archive_date'} = $ref2->{'arc_date'};
		    $DCPPExp{'request_date'} = $ref1->{'req_date'};
		}
		push(@DCPPExps, \%DCPPExp);
	    }
	    $CMIP6DCPP{'exps'} = [@DCPPExps];
	    $sth2->finish();
	}
	push(@CMIP6DCPPs, \%CMIP6DCPP);
	$sth1->finish();
    }
    $sth->finish();
    return @CMIP6DCPPs;
}

sub getCasesByType
{
    my $dbh = shift;
    my $expType_id = shift;
    my @cesmExps;
    my $sql = qq(select id, casename, title, DATE_FORMAT(archive_date, '%Y-%m-%d') as arc_date
               from t2_cases where expType_id = $expType_id order by casename);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %cesmExp;
	$cesmExp{'case_id'} = $ref->{'id'};
	$cesmExp{'casename'} = $ref->{'casename'};
	$cesmExp{'title'} = $ref->{'title'};
	$cesmExp{'archive_date'} = $ref->{'arc_date'};

	# TODO - get the status from the t2j_status 

	push(@cesmExps, \%cesmExp);
    }
    $sth->finish();
    return @cesmExps;
}

sub getCaseByID
{
    my $dbh = shift;
    my $id = shift;
    my (%case, %fields, %status, %project, %user) = ();
    my @notes;
    my @links;
    my @sorted;
    my $count = 0;
    my ($field_name, $process_name) = '';
    my ($sql1, $sth1);

    my $sql = qq(select * from t2_cases where id = $id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref())
    {
	$case{'case_id'} = $ref->{'id'};
	$case{'archive_date'} = $ref->{'archive_date'};
	$case{'casename'} = $ref->{'casename'};
	$case{'caseroot'} = $ref->{'caseroot'};
	$case{'caseuser'} = $ref->{'caseuser'};
	$case{'compiler'} = $ref->{'compiler'};
	$case{'compset'} = $ref->{'compset'};
	$case{'continue_run'} = $ref->{'continue_run'};
	$case{'dout_l_ms'} = $ref->{'dout_l_ms'};
	$case{'dout_l_msroot'} = $ref->{'dout_l_msroot'};
	$case{'dout_s'} = $ref->{'dout_s'};
	$case{'dout_s_root'} = $ref->{'dout_s_root'};

	# get the expType Name
	$case{'expType_name'} = "undefined";
	$case{'expType_desc'} = "undefined";

	if ( defined $ref->{'expType_id'} )
	{
	    $sql1 = qq(select name, description from t2_expType where id = $ref->{'expType_id'});
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute();
	    ($case{'expType_name'}, $case{'expType_desc'}) = $sth1->fetchrow();
	    $sth1->finish();
	}

	$case{'expType_id'} = $ref->{'expType_id'};	
	$case{'grid'} = $ref->{'grid'};
	$case{'is_ens'} = $ref->{'is_ens'};
	$case{'job_queue'} = $ref->{'job_queue'};
	$case{'job_time'} = $ref->{'job_time'};
	$case{'machine'} = $ref->{'machine'};
	$case{'model'} = $ref->{'model'};
	$case{'model_cost'} = $ref->{'model_cost'};
	$case{'model_throughput'} = $ref->{'model_throughput'};
	$case{'model_version'} = $ref->{'model_version'};
	$case{'mpilib'} = $ref->{'mpilib'};
	$case{'postprocess'} = $ref->{'postprocess'};
	$case{'project'} = $ref->{'project'};
	$case{'rest_n'} = $ref->{'rest_n'};
	$case{'rest_option'} = $ref->{'rest_option'};
	$case{'run_dir'} = $ref->{'run_dir'};
	$case{'run_lastdate'} = $ref->{'run_lastdate'};
	$case{'run_refcase'} = $ref->{'run_refcase'};
	$case{'run_refdate'} = $ref->{'run_refdate'};
	$case{'run_startdate'} = $ref->{'run_startdate'};
	$case{'run_type'} = $ref->{'run_type'};
	$case{'stop_n'} = $ref->{'stop_n'};
	$case{'stop_option'} = $ref->{'stop_option'};
	$case{'svn_repo_url'} = $ref->{'svn_repo_url'};
	$case{'svnuser_id'} = $ref->{'svnuser_id'};
	$case{'title'} = $ref->{'title'};
	$count++;
    }
    $sth->finish();

    # check the row count
    if (!$count) 
    {
	# no matching rows return case id = 0
	$case{'case_id'} = 0;
    }
    elsif ($count > 1)
    {
	# more than one matching row 
	# indicates a violation of constraints!!
	$case{'case_id'} = -1;
    }
    else 
    {
	# get CMIP6 fields 
	if ($case{'expType_id'} == 1) {
	    $sql = qq(select e.name as expName, m.name as mipName, j.variant_label, j.variant_info,
		      j.nyears, j.ensemble_num, j.ensemble_size, j.assign_id, j.science_id, j.source_type,
		     DATE_FORMAT(j.request_date, '%Y-%m-%d %H:%i') as req_date, j.deck_id, j.parentExp_id
		     from t2j_cmip6 as j, t2_cmip6_exps as e, t2_cmip6_MIP_types as m
		     where j.case_id = $case{'case_id'} and j.exp_id = e.id and j.design_mip_id = m.id);
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    while (my $ref = $sth->fetchrow_hashref())
	    {
		$project{'cmip6_expName'} = $ref->{'expName'};
		$project{'cmip6_mipName'} = $ref->{'mipName'};
		$project{'cmip6_variant_label'} = $ref->{'variant_label'};
		$project{'cmip6_variant_info'} = $ref->{'variant_info'};
		$project{'cmip6_ensemble_num'} = $ref->{'ensemble_num'};
		$project{'cmip6_ensemble_size'} = $ref->{'ensemble_size'};
		$project{'cmip6_nyears'} = $ref->{'nyears'};
		$project{'cmip6_request_date'} = $ref->{'req_date'};
		$project{'cmip6_source_type'} = $ref->{'source_type'};

		# get the DECK name if deck_id defined
		$project{'cmip6_deckName'} = '';
		if( defined($ref->{'deck_id'}) and ($ref->{'deck_id'} > 0) )
		{
		    $sql1 = qq(select name from t2_cmip6_DECK_types where id = $ref->{'deck_id'});
		    $sth1 = $dbh->prepare($sql1);
		    $sth1->execute();
		    $project{'cmip6_deckName'} = $sth1->fetchrow();
		    $sth1->finish();
		}

		# get the parent name if there is one
		$project{'cmip6_parent_casename'} = '';
		if( defined($ref->{'parentExp_id'}) and ($ref->{'parentExp_id'} > 0) )
		{
		    $sql1 = qq(select name, variant_label from t2_cmip6_exps where id = $ref->{'parentExp_id'});
		    $sth1 = $dbh->prepare($sql1);
		    $sth1->execute();
		    ($project{'cmip6_parent_expname'}, $project{'cmip6_parent_variant_label'}) = $sth1->fetchrow();
		    $sth1->finish();

		    $sql1 = qq(select c.casename from t2_cases as c, t2j_cmip6 as j
                               where j.exp_id = $ref->{'parentExp_id'} 
                               and j.case_id = c.id
                               and c.expType_id = 1);
		    $sth1 = $dbh->prepare($sql1);
		    $sth1->execute();
		    $project{'cmip6_parent_casename'} = $sth1->fetchrow();
		    $sth1->finish();
		}

		if( $ref->{'assign_id'} > 0 )
		{
		    %user = getUserByID($dbh, $ref->{'assign_id'});
		    $project{'cmip6_assign'} = $user{'firstname'} . ' ' . $user{'lastname'} . ' (' .$user{'email'} .')';
		}
		
		if( $ref->{'science_id'} > 0 )
		{
		    %user = getUserByID($dbh, $ref->{'science_id'});
		    $project{'cmip6_science'} = $user{'firstname'} . ' ' . $user{'lastname'} . ' (' . $user{'email'} . ')';
		}
	    }
	    $sth->finish();
	}

	# get case notes
	$sql = qq(select * from t2e_notes where case_id = $case{'case_id'}
                order by note, last_update desc);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    my %note;
	    $note{'note_id'} = $ref->{'id'};
	    $note{'note'} = $ref->{'note'};
	    $note{'last_update'} = $ref->{'last_update'};
	    push(@notes, \%note);
	}
	$sth->finish();

	# get changed fields
	$sql = qq(select * from t2e_fields where case_id = $case{'case_id'}
                order by field_name, last_update desc);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $field_name = $ref->{'field_name'};
	    $fields{$field_name}{'field_id'} = $ref->{'id'};
	    $fields{$field_name}{'field_value'} = $ref->{'field_value'};
	    $fields{$field_name}{'last_update'} = $ref->{'last_update'};
	}
	$sth->finish();

	# get process status
	$sql = qq(select p.name, p.description, s.code, s.color, j.last_update 
                from t2_process as p, t2_status as s,
                t2j_status as j where
                j.case_id = $case{'case_id'} and
                j.process_id = p.id and
                j.status_id = s.id
		order by p.name, j.last_update desc);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $process_name = $ref->{'name'};
	    $status{$process_name}{'description'} = $ref->{'description'};
	    $status{$process_name}{'code'} = $ref->{'code'};
	    $status{$process_name}{'color'} = $ref->{'color'};
	    $status{$process_name}{'last_update'} = $ref->{'last_update'};
	}
	$sth->finish();

	# get case links
	$sql = qq(select id from t2j_links where case_id = $case{'case_id'});
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    my $link = getLinkByID($dbh, $ref->{'id'});
	    push(@links, $link);
	}
	$sth->finish();

	# sort on process_id key
	@sorted = sort { $a->{process_id} <=> $b->{process_id} } @links;
    }
    return \%case, \%fields, \%status, \%project, \@notes, \@sorted;
}

sub getAllCases
{
    my $dbh = shift;
    my @cases;
    my $sql = "select id, casename from t2_cases order by casename";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %case;
	$case{'case_id'} = $ref->{'id'};
	$case{'casename'} = $ref->{'casename'};
	push(@cases, \%case);
    }
    $sth->finish();
    return @cases;
}


sub getNCARUsers
{
    my $dbh = shift;
    my @users;
    my $sql = "select user_id, lastname, firstname from t_svnusers where email like '%ucar%' order by lastname";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %user;
	$user{'user_id'} = $ref->{'user_id'};
	$user{'lastname'} = $ref->{'lastname'};
	$user{'firstname'} = $ref->{'firstname'};
	push(@users, \%user);
    }
    $sth->finish();
    return @users;
}

sub checkCase
{
    my $dbh = shift;
    my $case = shift;
    my $expType = shift;
    my ($case_id, $expType_id) = 0; 
    my ($expCount, $caseCount) = 0; 

    # get the expType_id
    $expType = $dbh->quote($expType);
    my $sql = qq(select count(id), id from t2_expType where name = $expType);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($expCount, $expType_id) = $sth->fetchrow();
    $sth->finish();
    if ($expCount != 0)
    {
	# get the case_id
	$case = $dbh->quote($case);
	$sql = qq(select count(id), id from t2_cases 
                     where casename = $case
                     and expType_id = $expType_id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	($caseCount, $case_id) = $sth->fetchrow();
	$sth->finish();
	if ($caseCount == 0)
	{
	    $case_id = 0;
	}
    }
    else 
    {
	$expType_id = 0;
    }
    return ($caseCount, $case_id, $expType_id);
}


sub getUserByID
{
    my $dbh = shift;
    my $user_id = shift;
    my %user = ();
    my $sql = "select lastname, firstname, email from t_svnusers where user_id = $user_id";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref())
    {
	$user{'lastname'} = $ref->{'lastname'};
	$user{'firstname'} = $ref->{'firstname'};
	$user{'email'} = $ref->{'email'};
    }

    return %user;
}

sub getPerfExperiments
{
    my $dbh = shift;
    my @perfExps;

#TODO - retrieve perf data for all experiments
    return @perfExps;
    
}


sub getCMIP6Sources
{
    my $dbh = shift;
    my @CMIP6Sources;
    my $sql = "select * from t2_cmip6_sources order by id";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %CMIP6Source;
	$CMIP6Source{'id'} = $ref->{'id'};
	$CMIP6Source{'name'} = $ref->{'name'};
	$CMIP6Source{'description'} = $ref->{'description'};

	push(@CMIP6Sources, \%CMIP6Source);
    }
    $sth->finish();
    return @CMIP6Sources;
}

sub checkSources
{
    my $dbh = shift;
    my $source_ref = shift;
    my @inSources = @{$source_ref};
    my $CMIP6Sources;
    my $valid = 1;
    my @associates;

    if (scalar @inSources == 0) {
	$valid = 0;
	return ($valid, @inSources);
    }
    
    while(my $CMIP6Source = shift(@inSources)) {
	if ($CMIP6Source ~~ [1,3]) {
	    my $sql = "select subtype_source_id from t2j_cmip6_source_types 
                       where parent_source_id = $CMIP6Source";
	    my @associates = @{$dbh->selectcol_arrayref($sql)};
	    # TODO - cross-check the associates array with
	    # inSources using the Array::Utils module
	}
	my $sql = "select name from t2_cmip6_sources 
                   where id = $CMIP6Source";
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $source_name = $sth->fetchrow();
	$sth->finish();
	$CMIP6Sources .= $source_name;
	$CMIP6Sources .= ' ';
    }
    
    $CMIP6Sources = $dbh->quote(substr($CMIP6Sources,0,-1));
    return ($valid, $CMIP6Sources);
}

sub getNoteByID
{
   my $dbh = shift;
   my $note_id = shift;

   my $sql = qq(select note from t2e_notes where id = $note_id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   my $note = $sth->fetchrow();
   $sth->finish();

   return $note;
}

sub getLinkByID
{
   my $dbh = shift;
   my $link_id = shift;
   my %link;

   my $sql = qq(select j.id, j.case_id, j.process_id, j.linkType_id, j.link, j.description, 
                DATE_FORMAT(j.last_update, '%Y-%m-%d'), c.casename, p.name, t.name
                from t2j_links as j, t2_cases as c, t2_process as p, t2_linkType as t
                where j.id = $link_id and j.case_id = c.id and j.process_id = p.id and j.linkType_id = t.id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   ($link{'link_id'},$link{'case_id'},$link{'process_id'},$link{'linkType_id'},$link{'link'},$link{'description'},$link{'last_update'},$link{'casename'},$link{'process_name'},$link{'linkType_name'})  = $sth->fetchrow();
   $sth->finish();

   return \%link;
}

sub getProcess
{
   my $dbh = shift;
   my @processes;

   my $sql = qq(select * from t2_process);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while(my $ref = $sth->fetchrow_hashref())
   {
       my %process;
       $process{'process_id'} = $ref->{'id'};
       $process{'process_name'} = $ref->{'name'};
       $process{'description'} = $ref->{'description'};
       push(@processes, \%process);
   }
   $sth->finish();
   return @processes;
}

sub getLinkTypes
{
   my $dbh = shift;
   my @linkTypes;

   my $sql = qq(select * from t2_linkType);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while(my $ref = $sth->fetchrow_hashref())
   {
       my %linkType;
       $linkType{'linkType_id'} = $ref->{'id'};
       $linkType{'linkType_name'} = $ref->{'name'};
       push(@linkTypes, \%linkType);
   }
   $sth->finish();
   return @linkTypes;
}

sub getCMIP6GlobalAttributes
{
   my $dbh = shift;
   my $case_id = shift;   
   my %globalAtts;

   my ($case, $fields, $status, $project, $notes, $links) = getCaseByID($dbh, $case_id);

   # massage the dates to get the correct format for CMIP6
   $globalAtts{'branch_time_in_child'} = '';
   $globalAtts{'branch_time_in_parent'} = '';

   my @child_times = split('-',$case->{'run_startdate'});
   my @parent_times = split('-',$case->{'run_refdate'});
   my $child_times = @child_times;
   my $parent_times = @parent_times;
   if ($parent_times > 0 && $child_times > 0) 
   {
       my $temp_time = ($child_times[0] - $parent_times[0]) * 365;
       $globalAtts{'branch_time_in_child'} = $temp_time . ".0DO";
       $temp_time = $parent_times[0] * 365;
       $globalAtts{'branch_time_in_parent'} = $temp_time . ".0DO";
   }
   elsif ($parent_times == 0 && $child_times > 0) 
   {
       my $temp_time = $child_times[0] * 365;
       $globalAtts{'branch_time_in_child'} = $temp_time . ".0DO";
   }       
   $globalAtts{'branch_method'} = $case->{'run_type'};
   $globalAtts{'experiment_id'} = $project->{'cmip6_expName'};
   $globalAtts{'parent_activity_id'} = $project->{'cmip6_mipName'};
   $globalAtts{'parent_experiment_id'} = $project->{'cmip6_parent_casename'};
   $globalAtts{'parent_variant_label'} = $project->{'cmip6_parent_variant_label'};
   $globalAtts{'source_type'} = $project->{'cmip6_source_type'};
   $globalAtts{'variant_info'} = $project->{'cmip6_variant_info'};
   $globalAtts{'variant_label'} = $project->{'cmip6_variant_label'};

   # construct the sub_experiment and sub_experiment_id
   $globalAtts{'sub_experiment'} = '';
   $globalAtts{'sub_experiment_id'} = '';
   if ($case->{'is_ens'} eq "true") 
   {
       $globalAtts{'sub_experiment'} = qq(ensemble member $project->{'cmip6_ens_num'} of $project->{'cmip6_ens_size'}) ;
       $globalAtts{'sub_experiment_id'} = qq(ensemble initilization date $case->{'run_startdate'});
   }

   return \%globalAtts;
}
