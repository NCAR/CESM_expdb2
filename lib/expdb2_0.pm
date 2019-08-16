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
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::Sendmail qw();
use lib "/home/www/html/csegdb/lib";
use config;

my %config = &getconfig;

@ISA = qw(Exporter);
@EXPORT = qw(getCasesByType getPerfExperiments getAllCases getNCARUsers getCMIP6Users checkCase 
getUserByID getNoteByID getLinkByID getProcess getLinkTypes getExpType getProcessStats 
getCaseFields getCaseFieldByName getCaseNotes getPercentComplete getDiags getCaseByID
updatePublishStatus getPublishStatus getEnsembles getLinkByTypeCaseID copySVNtrunkTag);

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
    my $sql = qq(select user_id, lastname, firstname from t_svnusers 
               where status = 'active' and lastname is not null order by lastname);
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

sub getCMIP6Users
{
    my $dbh = shift;
    my @users;
    my $sql = qq(select user_id, lastname, firstname from t_svnusers 
               where status = 'active' and lastname is not null 
               and is_cmip6 = 1 order by lastname);
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
    my ($sql, $sth);

    if ($user_id) {
	$sql = qq(select lastname, firstname, email from t_svnusers where user_id = $user_id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref())
	{
	    $user{'lastname'} = $ref->{'lastname'};
	    $user{'firstname'} = $ref->{'firstname'};
	    $user{'email'} = $ref->{'email'};
	}
	$sth->finish();
    }
    else {
	$user{'lastname'} = 'Unknown';
	$user{'firstname'} = '';
	$user{'email'} = '';
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
    my $sql = qq(select c.id, c.casename, t.name as expType 
               from t2_cases as c, t2_expType as t 
               where c.expType_id = t.id
               order by expType, casename);
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
                DATE_FORMAT(j.last_update, '%Y-%m-%d') as last_update, c.casename, p.name, t.name, 
                u.firstname, u.lastname, u.email 
                from t2j_links as j, t2_cases as c, t2_process as p, t2_linkType as t, t_svnusers as u
                where j.id = $link_id and j.case_id = c.id and j.process_id = p.id and 
                j.linkType_id = t.id and j.approver_id = u.user_id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   ($link{'link_id'},$link{'case_id'},$link{'process_id'},$link{'linkType_id'},$link{'link'},
    $link{'description'},$link{'last_update'},$link{'casename'},$link{'process_name'},
    $link{'linkType_name'},$link{'firstname'},$link{'lastname'},$link{'email'})  = $sth->fetchrow();
   $sth->finish();

   return \%link;
}

sub getProcess
{
   my $dbh = shift;
   my @processes;

   my $sql = qq(select * from t2_process order by name);
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
                j.disk_usage, j.disk_path, j.archive_method
                from t2_process as p, t2_status as s,
                t2j_status as j where
                j.case_id = $case_id and
                j.process_id = p.id and
                j.status_id = s.id and
                j.process_id = $process_id
                group by j.status_id, j.model_date
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
       $stat{'archive_method'} = $ref->{'archive_method'};
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
       my $field_name = $ref->{'field_name'};
       $field{$field_name}{'field_name'} = $field_name;
       $field{$field_name}{'field_value'} = $ref->{'field_value'};
       $field{$field_name}{'last_update'} = $ref->{'last_update'};
       push(@fields, \%field);
   }
   $sth->finish();
   return(@fields);
}

sub getCaseFieldByName
{
   my $dbh = shift;
   my $case_id = shift;
   my $field_name = shift;
   my @fields;
   
   my $sql = qq(select * from t2e_fields where 
                case_id = $case_id and
                field_name = '$field_name'
                order by last_update desc);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   while (my $ref = $sth->fetchrow_hashref())
   {
       my %field;
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

   my $sql = qq(select id, case_id, note, last_update, IFNULL(svnuser_id, 0) as svnuser_id 
                from t2e_notes where case_id = $case_id
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
    my $percent_complete = 0;

    if (defined $model_date && defined $start_date)
    {
	my @model_year = split(/-/, $model_date);
	my @start_year = split(/-/, $start_date);

	# check if the model year needs further parsing
	my $model_year = @model_year;
	my $model_yr = $model_year[0];
	if ($model_year == 2) {
	    $model_yr = substr($model_year[0], 0, 4);
	}

	if ($nyears && $model_yr && $start_year[0]) {
	    $percent_complete = (($model_yr - $start_year[0] + 0.0)/$nyears) * 100.0;
	}
    }
    return $percent_complete;
}


sub getCaseByID
{
    my $dbh = shift;
    my $id = shift;
    my (%case, %status, %user) = ();
    my @notes;
    my @links;
    my @sorted;
    my $count = 0;
    my ($firstname, $lastname, $email);
    my ($field_name, $process_name) = '';
    my ($sql1, $sth1, $value);

    my @fields = qw(archive_date casename caseroot caseuser compiler compset 
                    dout_s_root grid is_ens job_queue job_time machine model 
                    model_cost model_throughput model_version mpilib project 
                    rest_n rest_option run_dir run_lastdate run_refcase run_refdate 
                    run_startdate run_type stop_n stop_option svn_repo_url title);
    my @bool_fields = qw(continue_run dout_s postprocess);

    my $sql = qq(select count(*) from t2_cases where id = $id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($count) = $sth->fetchrow;
    $sth->finish();

    # check the row count
    if (!$count) 
    {
	# no matching rows return case id = 0
	$case{'case_id'}{'value'} = 0;
    }
    elsif ($count > 1)
    {
	# more than one matching row 
	# indicates a violation of constraints!!
	$case{'case_id'}{'value'} = -1;
    }
    else 
    {
	# set the case_id seperately
	$case{'case_id'}{'value'} = $id;
	$case{'case_id'}{'history'} = qw();

	# get all the fields and their history values
	foreach my $field (@fields) {
	    $sql = qq(select $field from t2_cases where id = $id);
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    $case{$field}{'value'} = $sth->fetchrow;
	    $sth->finish();

	    my @field_history = getCaseFieldByName($dbh, $id, $field);
	    $case{$field}{'history'} = \@field_history;
	    # if there is a history, update the display value to the most current
	    my $field_history = @field_history;
	    if ($field_history > 0) {
		$case{$field}{'value'} = $field_history[0]{'field_value'};
	    }
	}

	# get all the boolean fields and their history values
	foreach my $field (@bool_fields) {
	    $sql = qq(select $field from t2_cases where id = $id);
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    $value = $sth->fetchrow;
	    $value == 1 ? $case{$field}{'value'} = "True" : ($case{$field}{'value'} = "False");
	    $sth->finish();
	    
	    my @field_history = getCaseFieldByName($dbh, $id, $field);
	    $case{$field}{'history'} = \@field_history;
	}

	# get the expType name seperately
	$sql = qq(select count(expType_id), expType_id from t2_cases where id = $id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my ($count, $expType_id) = $sth->fetchrow;
	$sth->finish();

	if ($count) {
	    $sql = qq(select name, description from t2_expType where id = $expType_id);
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    ($case{'expType_name'}{'value'}, $case{'expType_desc'}{'value'}) = $sth->fetchrow();
	    $sth->finish();
	    $case{'expType_id'}{'value'} = $expType_id;
	}
	else {
	    $case{'expType_name'}{'value'} = "undefined";
	    $case{'expType_desc'}{'value'} = "undefined";
	    $case{'expType_id'}{'value'} = 0;
	}
	$case{'expType_name'}{'history'} = qw();
	$case{'expType_desc'}{'history'} = qw();

	# get the svnlogin name seperately
	$sql = qq(select count(u.user_id), u.firstname, u.lastname, u.email
                  from t_svnusers as u, t2_cases as t where
                  u.user_id = t.svnuser_id and
                  t.id = $id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	($count, $firstname, $lastname, $email) = $sth->fetchrow();
	if ($count) {
	    $case{'archiver'}{'value'} = $firstname . ' ' . $lastname . ': ' . $email
	}
	$sth->finish();
	my @field_history = getCaseFieldByName($dbh, $id, "svnuser_id");
	$case{'archiver'}{'history'} = \@field_history;

	# get case notes
	@notes = getCaseNotes($dbh, $id);
	
	# get process status
	$sql = qq(select p.name, p.description, s.code, s.color, j.last_update, j.model_date,
                j.disk_usage, j.disk_path, j.archive_method, IFNULL(j.user_id, 0) as user_id
                from t2_process as p, t2_status as s,
                t2j_status as j where
                j.case_id = $id and
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
	    $status{$process_name}{'archive_method'} = $ref->{'archive_method'};
	    my @fullstats = getProcessStats($dbh, $id, $process_name);
	    $status{$process_name}{'history'} = \@fullstats;
	    $status{$process_name}{'user_id'} = $ref->{'user_id'};
	    my %procUser = getUserByID($status{$process_name}{'user_id'});
	    $status{$process_name}{'user'} = \%procUser;
	}
	$sth->finish();

	# get case links
	$sql = qq(select id from t2j_links where case_id = $id);
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
    return \%case, \%status, \@notes, \@sorted;
}

sub updatePublishStatus
{
    my $dbh = shift;
    my $case_id = shift;
    my $process_id = shift;
    my $status_id = shift;
    my $user_id = shift;
    my $size = shift;

    my $size_mb = $dbh->quote($size);
    my $sql = qq(update t2j_status set status_id = $status_id,
                 archive_method = 'user', user_id = $user_id, last_update = NOW(),
                 disk_usage = $size_mb
                 where case_id = $case_id and process_id = $process_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish();

    return;
}


sub getPublishStatus
{
    my $dbh = shift;
    my $case_id = shift;
    my $process_id = shift;

    my $sql = qq(select s.code, j.status_id from t2j_status as j, t2_status as s
                 where j.case_id = $case_id and j.process_id = $process_id and
                 j.status_id = s.id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($statusCode, $status_id) = $sth->fetchrow();
    $sth->finish();

    return $statusCode, $status_id;
}

sub getEnsembles
{
    # gather all the ensmeble case id's and casenames into an array of hash references
    my $dbh = shift;
    my $case_id = shift;
    my (@cases);
    my (%case);

    my $sql = qq(select c.casename, j.ensemble_num, j.ensemble_size
                  from t2_cases as c, t2j_cmip6 as j 
                  where c.id = $case_id and c.id = j.case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    ($case{'casename'}, $case{'ens_num'}, $case{'ens_size'}) = $sth->fetchrow();
    $sth->finish();

    my ($base_name, $base_ext) = split(/\.([^\.]+)$/, $case{'casename'});
    for (my $i = 1; $i <= $case{'ens_size'}; $i++) {
	my %ca;
	my $ext = sprintf("%03d",$i);
	my $ens_casename = $dbh->quote($base_name . "." . $ext);
	$sql = qq(select IFNULL(id, 0) from t2_cases where casename = $ens_casename);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my ($ens_id) = $sth->fetchrow();
	$sth->finish();
	if ($ens_id > 0) {
	    $ca{'casename'} = $ens_casename;
	    $ca{'case_id'} = $ens_id;
	    push (@cases, \%ca);
	}
    }
    return @cases;
}       

sub getLinkByTypeCaseID
{
   my $dbh = shift;
   my $case_id = shift;
   my $process_name = shift;
   my $linkType_id = shift;
   my %link;

   my $sql = qq(select count(j.id), j.id, j.case_id, j.process_id, j.linkType_id, j.link, j.description, 
                DATE_FORMAT(j.last_update, '%Y-%m-%d') as last_update, c.casename, p.name, t.name, 
                u.firstname, u.lastname, u.email 
                from t2j_links as j, t2_cases as c, t2_process as p, t2_linkType as t, t_svnusers as u
                where j.case_id = c.id and j.process_id = p.id and 
                j.linkType_id = t.id and j.approver_id = u.user_id and
                p.name = "$process_name" and c.id = $case_id and j.linkType_id = $linkType_id);
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   ($link{'count'}, $link{'link_id'},$link{'case_id'},$link{'process_id'},$link{'linkType_id'},$link{'link'},
    $link{'description'},$link{'last_update'},$link{'casename'},$link{'process_name'},
    $link{'linkType_name'},$link{'firstname'},$link{'lastname'},$link{'email'})  = $sth->fetchrow();
   $sth->finish();

   return \%link;
}

sub copySVNtrunkTag
{
    my $dbh = shift;
    my $casename = shift;
    my $expdb2username = shift;
    my $expdb2password = shift;
    my $lemail = shift;

    my ($msgbody, $signal);

    my $dest_url = qq(https://svn-cesm2-expdb.cgd.ucar.edu/public/$casename);
    my $src_url = qq(https://svn-cesm2-expdb.cgd.ucar.edu/$casename/trunk);
    my @args = ("svn", "copy", $src_url, $dest_url, "--message", "copy caseroot trunk to public repo",
	"--username", $expdb2username, "--password", $expdb2password);
    system(@args);

    my $subject = qq(CESM2 experiments database copy status of caseroot to public SVN repo for $casename);
    # print return status to the SVN log file
    if ($? == -1) {
	$msgbody = <<EOF;
SVN copy command failed to execute with error = $!.

Please contact help\@cgd.ucar.edu for assistance.
EOF
    }
    elsif ($? & 127) {
	$signal = ($? & 127);
	$msgbody = <<EOF;
SVN copy command died with signal = $signal.

Please contact help\@cgd.ucar.edu for assistance.
EOF
    }
    else {
	$msgbody = <<EOF;
SVN copy command completed successfully. Publicly accessible caseroot files are available at URL:

$dest_url
EOF
    }

    # send emails to user with error message
    my $email = Email::Simple->create(
	header => [
	    From => "CESM-expdb2",
	    To   => "$lemail",
	    Subject => $subject,
	],
	body => $msgbody,
	);

    sendmail($email, 
	     { from => $lemail,
	       transport => Email::Sender::Transport::Sendmail->new}
	) or die "can't send email to $lemail in copySVNtrunkTag";
}
