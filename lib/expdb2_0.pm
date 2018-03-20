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
getUserByID getNoteByID getLinkByID getProcess getLinkTypes getExpType);

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
