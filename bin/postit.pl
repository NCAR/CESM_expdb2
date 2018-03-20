#!/usr/bin/env perl
#
# postit - receive a cylc workflow generated email with
#          process status and update the expdb2.0 
#          database accordingly.
#
use strict;
use DBI;
use DBD::mysql;
use lib qw(.);
use Mail::Internet;
use Date::Manip;

# set up the logger
use Log::Log4perl;
Log::Log4perl->init("/usr/local/expdb-2.0.0/conf/expdb-mail-log.conf");
my $logger = Log::Log4perl->get_logger();

use lib "/home/www/html/csegdb/lib";
use config;

use lib "/home/www/html/expdb2.0/lib";
use expdb2_0;
use CMIP6;

# Get the necessary config vars for the database
my %config = &getconfig;
my $version_id = $config{'version_id'};
my $dbname = $config{'dbname'};
my $dbhost = $config{'dbhost'};
my $dbuser = $config{'dbuser'};
my $dbpasswd = $config{'dbpassword'};
my $dsn = $config{'dsn'};

my $dbh = DBI->connect($dsn, $dbuser, $dbpasswd) or die "unable to connect to db: $DBI::errstr";

# parse the incoming mail message from STDIN
my $mail = Mail::Internet->new(\*STDIN);
my $subject = $mail->head->get("Subject");
my $date = $mail->head->get("Date");
my @body = $mail->tidy_body();

# check for string !!cylc alert!! in the subject
chomp($subject);
if (index($subject, "cylc alert") == -1)
{
    $logger->logdie("Invalid subject line '" . $subject ."'");
}

# split the Subject line to get the status
my @subjects = split(/ /,$subject);
my $new_status = $subjects[-1]; 
chomp($new_status);

# get the casename
my @names = split(/\./,$subjects[-2]);
my $casename = join('.',@names[0..$#names-2]);
chomp($casename);

# loop through the body to get the SUITE and MESSAGE strings
my $expType = '';
my $process = '';
my $model_date = '';
while (my $line = shift @body[0])
{
    chomp($line);
    if (index($line, "SUITE:") != -1)
    {
	$line =~ s/SUITE: //;
	my @suite = split(/\./,$line);
	$expType =  lc($suite[-1]);
    }
    elsif (index($line, "MESSAGE:") != -1)
    {
	$line =~ s/MESSAGE: //;
	my @message = split(/_/,$line);
	$model_date = $dbh->quote($message[-1]);
	$process = $dbh->quote(join('_',@message[0..($#message-1)]));
	last;
    }
}

# given the date, casename, expType, process and status, update the database tables
my ($count, $case_id, $expType_id) = checkCase($dbh, $casename, $expType);
if (!$count)
{
    $logger->logdie("Casename does not exist. Run archive_metadata first or reserve a CMIP6 casename in the expdb2.0 dashboard '" . $casename ."' / '" . $expType . "'");
}
if ($count > 1)
{
    $logger->logdie("Casename and expType are not unique '" . $casename ."' " . "'" . $expType . "'");
}

# check the process status for the matching casename
my $sql = qq(select count(j.case_id), j.status_id, j.process_id, s.code, p.name,
             DATE_FORMAT(j.last_update,'%Y-%m-%d %H:%i:%s'), j.model_date
             from t2j_status as j, t2_status as s, t2_process as p
             where j.case_id = $case_id
             and j.status_id = s.id
             and j.process_id = p.id
             and p.name = $process
             order by j.last_update DESC
             limit 1);
my $sth = $dbh->prepare($sql);
$sth->execute() or $logger->logdie("SQL error: " . $dbh->errstr);
my ($count, $status_id, $process_id, $current_status, $process, $last_update, $db_model_date) = $sth->fetchrow();
$sth->finish();

# get the new status code
$new_status = $dbh->quote($new_status);
$sql = qq(select id from t2_status 
             where lower(code) = $new_status);
$sth = $dbh->prepare($sql);
$sth->execute() or $logger->logdie("SQL error: " . $dbh->errstr);
my ($new_status_id) = $sth->fetchrow();
$sth->finish();

# compare dates to make sure this is a newer status email
my $date_obj = new Date::Manip::Date;
my $date1 = $date_obj->new_date;
my $date2 = $date_obj->new_date;
chomp($date);
$date1->parse($date);
$date2->parse($last_update);
if ($date1->cmp($date2) > 0) {
    # insert the new status
    $sql = qq(insert into t2j_status (case_id, status_id, process_id, last_update, model_date)
              value ($case_id, $new_status_id, $process_id, NOW(), $model_date));
    $sth = $dbh->prepare($sql);
    $sth->execute() or $logger->logdie("SQL error: " . $dbh->errstr);
    $sth->finish();
}
$dbh->disconnect;

