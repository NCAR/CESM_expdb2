package CMIP6;
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
use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;

@ISA = qw(Exporter);
@EXPORT = qw(getCMIP6Experiments getCMIP6MIPs getCMIP6DECKs getCMIP6DCPPs getCMIP6Sources 
getCMIP6CaseByID checkCMIP6Sources CMIP6publishDSET);

sub getCMIP6Experiments
{
    my $dbh = shift;
    my ($sql1, $sth1);
    my ($sql2, $sth2);
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
	$sql1 = qq(select count(case_id) from t2j_cmip6 
                   where case_id is not null and exp_id = $CMIP6Exp{'exp_id'});
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	my $count = $sth1->fetchrow();
	$sth1->finish();
	if( $count ) {
	    $sql1 = qq(select case_id from t2j_cmip6 
                   where case_id is not null and exp_id = $CMIP6Exp{'exp_id'});
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute();
	    while(my $ref1 = $sth1->fetchrow_hashref())
	    {
		my %CMIP6EnsExp;
		$CMIP6EnsExp{'exp_id'} = $ref->{'id'};
		$CMIP6EnsExp{'expName'} = $ref->{'name'};
		$CMIP6EnsExp{'description'} = $ref->{'description'};
		$CMIP6EnsExp{'cmip6_exp_uid'} = $ref->{'uid'};
		$CMIP6EnsExp{'designMIP'} = $ref->{'design_mip'};
		$CMIP6EnsExp{'case_id'} = $ref1->{'case_id'};
		$sql2 = qq(select casename from t2_cases where id = $CMIP6EnsExp{'case_id'} and expType_id = 1);
		##print STDERR ">>> sql2 = " . $sql2;
		$sth2 = $dbh->prepare($sql2);
		$sth2->execute();
		$CMIP6EnsExp{'casename'} = $sth2->fetchrow();
		##print STDERR ">>> casname = " . $CMIP6EnsExp{'casename'};
		$sth2->finish();
		push(@CMIP6Exps, \%CMIP6EnsExp);
	    }
	    $sth1->finish();
	}
	else {
	    push(@CMIP6Exps, \%CMIP6Exp);
	}
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

sub getCMIP6CaseByID
{
    my $dbh = shift;
    my $id = shift;
    my (%case, %fields, %status, %project, %user, %globalAtts) = ();
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
	$sql = qq(select e.name as expName, e.description as expDesc, m.name as mipName, m.description as mipDesc, j.variant_label, 
                  j.nyears, j.ensemble_num, j.ensemble_size, j.assign_id, j.science_id, j.source_type,
	          DATE_FORMAT(j.request_date, '%Y-%m-%d %H:%i') as req_date, j.deck_id, j.parentExp_id
		  from t2j_cmip6 as j, t2_cmip6_exps as e, t2_cmip6_MIP_types as m
		  where j.case_id = $case{'case_id'} and j.exp_id = e.id and j.design_mip_id = m.id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $project{'cmip6_expName'} = $ref->{'expName'};
	    $project{'cmip6_expDescription'} = $ref->{'expDesc'};
	    $project{'cmip6_mipName'} = $ref->{'mipName'};
	    $project{'cmip6_mipDescription'} = $ref->{'mipDesc'};
	    $project{'cmip6_variant_label'} = $ref->{'variant_label'};
	    $project{'cmip6_variant_info'} = $case{'title'};
	    $project{'cmip6_ensemble_num'} = $ref->{'ensemble_num'};
	    $project{'cmip6_ensemble_size'} = $ref->{'ensemble_size'};
	    $project{'cmip6_nyears'} = $ref->{'nyears'};
	    $project{'cmip6_request_date'} = $ref->{'req_date'};
	    $project{'cmip6_source_type'} = $ref->{'source_type'};

	    # get the DECK name if deck_id defined
	    $project{'cmip6_deckName'} = '';
	    if( defined($ref->{'deck_id'}) and ($ref->{'deck_id'} > 0) )
	    {
		$sql1 = qq(select name, description from t2_cmip6_DECK_types where id = $ref->{'deck_id'});
		$sth1 = $dbh->prepare($sql1);
		$sth1->execute();
		($project{'cmip6_deckName'}, $project{'cmip6_deckDescription'}) = $sth1->fetchrow();
		$sth1->finish();
	    }

	    # get the parent name if there is one
	    $project{'cmip6_parent_casename'} = '';
	    if( defined($ref->{'parentExp_id'}))
	    {
		$sql1 = qq(select e.name, c.title, c.casename, j.variant_label, e.description
                           from t2_cmip6_exps as e, t2_cases as c,
                           t2j_cmip6 as j 
                           where c.id = j.case_id
                           and j.exp_id = $ref->{'parentExp_id'}
                           and e.id = j.exp_id);
		$sth1 = $dbh->prepare($sql1);
		$sth1->execute();
		($project{'cmip6_parent_expname'}, $project{'cmip6_parent_variant_info'},
		 $project{'cmip6_parent_casename'}, $project{'cmip6_parent_variant_label'},
		 $project{'cmip6_parent_description'}) = $sth1->fetchrow();
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

	# get case notes
	$sql = qq(select * from t2e_notes where case_id = $case{'case_id'}
                order by last_update desc);
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

	# get the global Attributes
	$globalAtts{'branch_time_in_child'} = '';
	$globalAtts{'branch_time_in_parent'} = '';

	my @temp = split(' ',$case{'run_startdate'});
	my @child_times = split('-',$temp[0]);

	@temp = split(' ',$case{'run_refdate'});
	my @parent_times = split('-',$temp[0]);

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
	$globalAtts{'branch_method'} = $case{'run_type'};
	$globalAtts{'experiment_id'} = $project{'cmip6_expName'};
	$globalAtts{'parent_activity_id'} = $project{'cmip6_mipName'};
	$globalAtts{'parent_experiment_id'} = $project{'cmip6_parent_casename'};
	$globalAtts{'parent_variant_label'} = $project{'cmip6_parent_variant_label'};
	$globalAtts{'source_type'} = $project{'cmip6_source_type'};
	$globalAtts{'variant_info'} = $project{'cmip6_variant_info'};
	$globalAtts{'variant_label'} = $project{'cmip6_variant_label'};

	# construct the sub_experiment and sub_experiment_id
	$globalAtts{'sub_experiment'} = '';
	$globalAtts{'sub_experiment_id'} = '';
	if ($case{'is_ens'} eq "true") 
	{
	    $globalAtts{'sub_experiment'} = qq(s$child_times[0]-$project{'cmip6_variant_label'}) ;
	    $globalAtts{'sub_experiment_id'} = qq(s$child_times[0]);
	}
    }
    return \%case, \%fields, \%status, \%project, \@notes, \@sorted, \%globalAtts;
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

sub checkCMIP6Sources
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


sub CMIP6publishDSET
{
    my $dbh = shift;
    my $id = shift;
    my (%case, %fields, %user) = ();
    my @notes;
    my @links;
    my $count = 0;
    my ($field_name) = '';
    my ($sql1, $sth1);

    my $sql = qq(select * from t2_cases where id = $id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref())
    {
	$case{'case_id'} = $ref->{'id'};
	$case{'archive_date'} = $ref->{'archive_date'};
	$case{'casename'} = $ref->{'casename'};
	$case{'compiler'} = $ref->{'compiler'};
	$case{'compset'} = $ref->{'compset'};

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

	$case{'grid'} = $ref->{'grid'};
	$case{'is_ens'} = $ref->{'is_ens'};
	$case{'machine'} = $ref->{'machine'};
	$case{'model'} = $ref->{'model'};
	$case{'model_cost'} = $ref->{'model_cost'};
	$case{'model_throughput'} = $ref->{'model_throughput'};
	$case{'model_version'} = $ref->{'model_version'};
	$case{'mpilib'} = $ref->{'mpilib'};
	$case{'run_lastdate'} = $ref->{'run_lastdate'};
	$case{'run_refcase'} = $ref->{'run_refcase'};
	$case{'run_refdate'} = $ref->{'run_refdate'};
	$case{'run_startdate'} = $ref->{'run_startdate'};
	$case{'run_type'} = $ref->{'run_type'};
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
	$sql = qq(select e.name as expName, e.description as expDesc, m.name as mipName, m.description as mipDesc, j.variant_label, 
                  j.nyears, j.ensemble_num, j.ensemble_size, j.assign_id, j.science_id, j.source_type,
	          DATE_FORMAT(j.request_date, '%Y-%m-%d %H:%i') as req_date, j.deck_id, j.parentExp_id
		  from t2j_cmip6 as j, t2_cmip6_exps as e, t2_cmip6_MIP_types as m
		  where j.case_id = $case{'case_id'} and j.exp_id = e.id and j.design_mip_id = m.id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $case{'cmip6_expName'} = $ref->{'expName'};
	    $case{'cmip6_expDescription'} = $ref->{'expDesc'};
	    $case{'cmip6_mipName'} = $ref->{'mipName'};
	    $case{'cmip6_mipDescription'} = $ref->{'mipDesc'};
	    $case{'cmip6_variant_label'} = $ref->{'variant_label'};
	    $case{'cmip6_variant_info'} = $case{'title'};
	    $case{'cmip6_ensemble_num'} = $ref->{'ensemble_num'};
	    $case{'cmip6_ensemble_size'} = $ref->{'ensemble_size'};
	    $case{'cmip6_nyears'} = $ref->{'nyears'};
	    $case{'cmip6_request_date'} = $ref->{'req_date'};
	    $case{'cmip6_source_type'} = $ref->{'source_type'};

	    # get the DECK name if deck_id defined
	    $case{'cmip6_deckName'} = '';
	    if( defined($ref->{'deck_id'}) and ($ref->{'deck_id'} > 0) )
	    {
		$sql1 = qq(select name, description from t2_cmip6_DECK_types where id = $ref->{'deck_id'});
		$sth1 = $dbh->prepare($sql1);
		$sth1->execute();
		($case{'cmip6_deckName'}, $case{'cmip6_deckDescription'}) = $sth1->fetchrow();
		$sth1->finish();
	    }

	    # get the parent name if there is one
	    $case{'cmip6_parent_casename'} = '';
	    if( defined($ref->{'parentExp_id'}))
	    {
		$sql1 = qq(select e.name, c.title, c.casename, j.variant_label, e.description
                           from t2_cmip6_exps as e, t2_cases as c,
                           t2j_cmip6 as j 
                           where c.id = j.case_id
                           and j.exp_id = $ref->{'parentExp_id'}
                           and e.id = j.exp_id);
		$sth1 = $dbh->prepare($sql1);
		$sth1->execute();
		($case{'cmip6_parent_expname'}, $case{'cmip6_parent_variant_info'},
		 $case{'cmip6_parent_casename'}, $case{'cmip6_parent_variant_label'},
		 $case{'cmip6_parent_description'}) = $sth1->fetchrow();
		$sth1->finish();
	    }

	    if( $ref->{'science_id'} > 0 )
	    {
		%user = getUserByID($dbh, $ref->{'science_id'});
		$case{'cmip6_scienceLiaison'} = $user{'firstname'} . ' ' . $user{'lastname'} . ' (' . $user{'email'} . ')';
	    }
	}
	$sth->finish();

	# get case notes
	$sql = qq(select * from t2e_notes where case_id = $case{'case_id'}
                order by last_update desc);
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
    }
    return \%case, \%fields, \@notes, \@links;
}



