# THIS MAY NOT BE NEEDED _ CAN DO ALL IN EXPDB2_0.pm
package query2_0;
use warnings;
use strict;
use DBI;
use DBD::mysql;
use Time::localtime;
use vars qw(@ISA @EXPORT);
use Exporter;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser); 
use CGI::Session qw/-ip-match/;
use lib "/home/www/html/csegdb/lib";
use config;

@ISA = qw(Exporter);
@EXPORT = qw(checkCaseExists);

sub checkCaseExists
{
    my $dbh = shift;
    my $casename = shift;

    $casename = $dbh->quote($casename);
    my $sql = qq(select count(id) from t2_cases where casename = $casename);
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my $count = $sth->fetchrow;
    $sth->finish();

    # return the count value as True or False
    my $returnCode = 'True'; 
    if ($count == 0) {
	$returnCode = 'False';
    }

    return $returnCode;
}
