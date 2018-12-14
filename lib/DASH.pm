package DASH;
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
@EXPORT = qw(getHorizontalResolutions getTemporalResolutions getExpAttributes
getExpTypes getExpPeriods getComponents);

sub getHorizontalResolutions
{
    my $dbh = shift;
    my @horizontalResolutions;

    my $sql = qq(select * from t2_DASH_horizontalResolution);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %horizontalResolution;
	$horizontalResolution{'id'} = $ref->{'id'};
	$horizontalResolution{'name'} = $ref->{'name'};

	push(@horizontalResolutions, \%horizontalResolution);
    }
    $sth->finish();
    return @horizontalResolutions;
}


sub getTemporalResolutions
{
    my $dbh = shift;
    my @temporalResolutions;

    my $sql = qq(select * from t2_DASH_temporalResolution);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %temporalResolution;
	$temporalResolution{'id'} = $ref->{'id'};
	$temporalResolution{'name'} = $ref->{'name'};

	push(@temporalResolutions, \%temporalResolution);
    }
    $sth->finish();
    return @temporalResolutions;
}


sub getExpAttributes
{
    my $dbh = shift;
    my @expAttributes;

    my $sql = qq(select * from t2_DASH_expAttributes);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %expAttribute;
	$expAttribute{'id'} = $ref->{'id'};
	$expAttribute{'name'} = $ref->{'name'};
	$expAttribute{'description'} = $ref->{'description'};

	push(@expAttributes, \%expAttribute);
    }
    $sth->finish();
    return @expAttributes;
}


sub getExpTypes
{
    my $dbh = shift;
    my @expTypes;

    my $sql = qq(select * from t2_DASH_expType);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %expType;
	$expType{'id'} = $ref->{'id'};
	$expType{'name'} = $ref->{'name'};

	push(@expTypes, \%expType);
    }
    $sth->finish();
    return @expTypes;
}


sub getExpPeriods
{
    my $dbh = shift;
    my @expPeriods;

    my $sql = qq(select * from t2_DASH_expPeriod);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %expPeriod;
	$expPeriod{'id'} = $ref->{'id'};
	$expPeriod{'name'} = $ref->{'name'};

	push(@expPeriods, \%expPeriod);
    }
    $sth->finish();
    return @expPeriods;
}


sub getComponents
{
    my $dbh = shift;
    my @components;

    my $sql = qq(select * from t2_DASH_components);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %component;
	$component{'id'} = $ref->{'id'};
	$component{'name'} = $ref->{'name'};
	$component{'description'} = $ref->{'description'};

	push(@components, \%component);
    }
    $sth->finish();
    return @components;
}

