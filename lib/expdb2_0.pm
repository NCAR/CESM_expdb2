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
@EXPORT = qw(getCasesByType getPerfExperiments getAllCases getNCARUsers checkCase 
getUserByID getNoteByID getLinkByID getProcess getLinkTypes getExpType getProcessStats 
getCaseFields getCaseNotes getPercentComplete getDiags getCaseByID);

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

sub getNCARUsers
{
    my $dbh = shift;
    my @users;
    my $sql = "select user_id, lastname, firstname from t_svnusers 
               where status = 'active' and lastname is not null order by lastname";
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

sub getAllCases
{
    my $dbh = shift;
    my @cases;
    my $sql = "select c.id, c.casename, t.name as expType 
               from t2_cases as c, t2_expType as t 
               where c.expType_id = t.id
               order by expType, casename";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %case;
	$case{'case_id'} = $ref->{'id'};
	$case{'casename'} = $ref->{'casename'};
	$case{'expType'} = $ref->{'expType'};
	push(@cases, \%case);
    }
    $sth->finish();
    return @cases;
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

sub getExpType
{
   my $dbh = shift;
   my $case_id = shift;
   my %expType;

   my $sql = qq(select e.id, e.name, e.description, e.exp_module, e.getCaseByID, e.expDetail_template 
                from t2_expType as e, t2_cases as c
                where e.id = c.expType_id and c.id = $case_id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while(my $ref = $sth->fetchrow_hashref())
   {
       $expType{'id'} = $ref->{'id'};
       $expType{'name'} = $ref->{'name'};
       $expType{'description'} = $ref->{'description'};
       $expType{'exp_module'} = $ref->{'exp_module'};
       $expType{'getCaseByID'} = $ref->{'getCaseByID'};
       $expType{'expDetail_template'} = $ref->{'expDetail_template'};
   }
   $sth->finish();
   return \%expType;
}

sub getProcessStats
{
   my $dbh = shift;
   my $case_id = shift;
   my $processName = shift;

   my @stats;

   # get the casename
   my $sql = qq(select casename from t2_cases where id = $case_id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   my $casename = $sth->fetchrow();
   $sth->finish();

   # get the process id 
   my $pn = $dbh->quote($processName);
   $sql = qq(select id from t2_process where name = $pn);
   $sth = $dbh->prepare($sql);
   $sth->execute();
   my $process_id = $sth->fetchrow();
   $sth->finish();

   $sql = qq(select p.name, p.description, s.code, s.color, j.last_update, j.model_date, 
                j.disk_usage, j.disk_path
                from t2_process as p, t2_status as s,
                t2j_status as j where
                j.case_id = $case_id and
                j.process_id = p.id and
                j.status_id = s.id and
                j.process_id = $process_id
		order by p.name, j.last_update asc);
   $sth = $dbh->prepare($sql);
   $sth->execute();
   while(my $ref = $sth->fetchrow_hashref())
   {
       my %stat;
       $stat{'process_name'} = $ref->{'name'};
       $stat{'description'} = $ref->{'description'};
       $stat{'code'} = $ref->{'code'};
       $stat{'color'} = $ref->{'color'};
       $stat{'last_update'} = $ref->{'last_update'};
       $stat{'model_date'} = $ref->{'model_date'};
       $stat{'disk_usage'} = $ref->{'disk_usage'};
       $stat{'disk_path'} = $ref->{'disk_path'};
       push(@stats, \%stat);
   }
   $sth->finish();
   return ($casename, @stats);
}

sub getCaseFields
{
   my $dbh = shift;
   my $case_id = shift;
   my @fields;

   my $sql = qq(select * from t2e_fields where 
                case_id = $case_id
                order by field_name, last_update desc);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while (my $ref = $sth->fetchrow_hashref())
   {
       my %field;
       $field{'field_name'} = $ref->{'field_name'};
       $field{'field_value'} = $ref->{'field_value'};
       $field{'last_update'} = $ref->{'last_update'};
       push(@fields, \%field);
   }
   $sth->finish();
   return(@fields);
}

sub getCaseNotes
{
   my $dbh = shift;
   my $case_id = shift;
   my @notes;

   my $sql = qq(select * from t2e_notes where case_id = $case_id
                order by last_update asc);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while (my $ref = $sth->fetchrow_hashref())
   {
       my %note;
       my %user;
       $note{'note_id'} = $ref->{'id'};
       $note{'note'} = $ref->{'note'};
       $note{'last_update'} = $ref->{'last_update'};
       %user = getUserByID($dbh, $ref->{'svnuser_id'});
       $note{'firstname'} = $user{'firstname'};
       $note{'lastname'} = $user{'lastname'};
       $note{'email'} = $user{'email'};
       push(@notes, \%note);
   }
   $sth->finish();
   return(@notes);
}

sub getPercentComplete
{
    my $model_date = shift;
    my $nyears = shift;
    my $start_date = shift;

    my @model_year = split(/-/, $model_date);
    my @start_year = split(/-/, $start_date);

    my $percent_complete = 0;
    if ($nyears) {
	$percent_complete = (($model_year[0] - $start_year[0] + 0.0)/$nyears) * 100.0;
    }

    return $percent_complete;
}


sub getDiags
{
   my $dbh = shift;
   my @diags;

   # get all the casenames and id's for published diags from the t2j_links table
   return (@diags);
}


sub getCaseByID
{
    my $dbh = shift;
    my $id = shift;
    my (%case, %status, %user) = ();
    my @fields;
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
	$case{'expType_template'} = "undefined";

	if ( defined $ref->{'expType_id'} )
	{
	    $sql1 = qq(select name, description, expDetail_template from t2_expType where id = $ref->{'expType_id'});
	    $sth1 = $dbh->prepare($sql1);
	    $sth1->execute();
	    ($case{'expType_name'}, $case{'expType_desc'}, $case{'expType_template'}) = $sth1->fetchrow();
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
	# get case fields
	@fields = getCaseFields($dbh, $case{'case_id'});

	# get case notes
	@notes = getCaseNotes($dbh, $case{'case_id'});

	# get process status
	$sql = qq(select p.name, p.description, s.code, s.color, j.last_update, j.model_date,
                j.disk_usage, j.disk_path
                from t2_process as p, t2_status as s,
                t2j_status as j where
                j.case_id = $case{'case_id'} and
                j.process_id = p.id and
                j.status_id = s.id
		order by p.name, j.last_update asc);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $process_name = $ref->{'name'};
	    $status{$process_name}{'description'} = $ref->{'description'};
	    $status{$process_name}{'code'} = $ref->{'code'};
	    $status{$process_name}{'color'} = $ref->{'color'};
	    $status{$process_name}{'last_update'} = $ref->{'last_update'};
	    $status{$process_name}{'model_date'} = $ref->{'model_date'};
	    $status{$process_name}{'disk_usage'} = $ref->{'disk_usage'};
	    $status{$process_name}{'disk_path'} = $ref->{'disk_path'};
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
    return \%case, \@fields, \%status, \@notes, \@sorted;
}
