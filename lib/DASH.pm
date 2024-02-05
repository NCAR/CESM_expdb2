package DASH;
use warnings; no warnings 'uninitialized';
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
use SVN::Client;
use lib "/var/www/html/csegdb/lib";
use config;
use lib "/var/www/html/expdb2.0/lib";
use CMIP6;
use expdb2_0;

@ISA = qw(Exporter);
@EXPORT = qw(getHorizontalResolutions getTemporalResolutions getExpAttributes
getExpTypes getExpPeriods getComponents getWorkingGroups getDASHFields);


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
	$expAttribute{'short_name'} = $ref->{'short_name'};
	$expAttribute{'name'} = $ref->{'name'};

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
	$component{'short_name'} = $ref->{'short_name'};
	$component{'name'} = $ref->{'name'};

	push(@components, \%component);
    }
    $sth->finish();
    return @components;
}

sub getWorkingGroups
{
    my $dbh = shift;
    my @wgs;

    my $sql = qq(select id, name from t_workingGroup);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	my %wg;
	$wg{'id'} = $ref->{'id'};
	$wg{'name'} = $ref->{'name'};

	push(@wgs, \%wg);
    }
    $sth->finish();
    return @wgs;
}

sub getDASHFields
{
    my $dbh = shift;
    my $case_id = shift;
    my $expType_id = shift;
    my %DASHFields;
    my ($project, $globalAtts);
    my ($table_id, $table_name, $keyword);
    my ($sql1, $sth1);
    my ($kw_list) = '';
    my ($keywords) = '';
    my (@links, @stats);
    my $cmip6_exp_uid;
    my ($compset, $grid);
    my $last_ens;

    # get the current process stats for DASH publication
    ($DASHFields{'casename'}, @stats) = getProcessStats($dbh, $case_id, 'publish_dash');
    $DASHFields{'publication_date'} = '';
    if (@stats > 0) {
	$DASHFields{'publication_date'} = $stats[0]->{'last_update'};
	$DASHFields{'publication_date'} = substr($DASHFields{'publication_date'}, 0, 10);
    }

    # gather the necessary DASH fields for given experiment
    my $sql = qq(select atm_lat, atm_lon, ocn_lat, ocn_lon, count(*)
                 from t2_DASH_spatialResolution
                 where case_id = $case_id);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($atm_lat, $atm_lon, $ocn_lat, $ocn_lon, $count) = $sth->fetchrow();
    $sth->finish();

    $DASHFields{'spatial_resolution'} = '';
    if ($count > 0) {
	$DASHFields{'spatial_resolution'} = qq([{"distance": "$atm_lat", "units": "latitude_resolution_atmosphere_land_degrees"}, 
                                             {"distance": "$atm_lon", "units": "longitude_resolution_atmosphere_land_degrees"},
                                             {"distance": "$ocn_lat", "units": "latitude_resolution_ocean_seaice_degrees"}, 
                                             {"distance": "$ocn_lon", "units": "longitude_resolution_ocean_seaice_degrees"}]);
    }

    # get experiment specific fields 
    if ($expType_id == 1) {
	($globalAtts, $project) = getCMIP6GlobalFileAtts($dbh, $case_id, '');
	# for display purposes
	if ($project->{'cmip6_ensemble_size'} == 0) {
	    $project->{'cmip6_ensemble_size'} = 1;
	}
	$cmip6_exp_uid = $project->{'cmip6_exp_uid'};
	$DASHFields{'abstract'} = qq($project->{'cmip6_experiment'} (CMIP6 Experiment).\n\nUsers can access the data from the Earth System Grid Federation or Climate Data Gateway as registered users; see the \'Related links\' section.\n\nDiagnostic plots are also available from the \'Related links\'.\n\nNCAR users may access the data from Glade; path(s) listed in the \'Additional Information\' section.);

	if ($project->{'cmip6_ensemble_size'} > 1 && $stats[0]->{'pub_ens'} > 0) {
	    $last_ens = sprintf("%03d", $project->{'cmip6_ensemble_size'});
	    $DASHFields{'abstract'} = qq($project->{'cmip6_experiment'} (CMIP6 Experiment).\n\nUsers can access the data from the Earth System Grid Federation or Climate Data Gateway as registered users; see the \'Related links\' section.\n\nDiagnostic plots are also available from the \'Related links\'.\n\nNCAR users may access the data from Glade; path(s) listed in the \'Additional Information\' section.\n\nThis is the only DASH metadata record for members 001 through $last_ens of a $project->{'cmip6_ensemble_size'} member ensemble set.);
	}

	$DASHFields{'alternate_identifier'} = qq(["$project->{'cmip6_experiment_id'} (CMIP6 Experiment ID)",
                    "$project->{'cmip6_source_id'} (CMIP6 CESM Model Source)",
                    "$project->{'cmip6_variant_label'} (CMIP6 Variant Label)",
                    "$project->{'cmip6_mipName'} (CMIP6 MIP Name)",
                    "$project->{'cmip6_ensemble_num'} (CMIP6 Ensemble Number)",
                    "$project->{'cmip6_ensemble_size'} (CMIP6 Ensemble Size)",
                    "$project->{'cmip6_nyears'} (CMIP6 Minimum Number of Years)",
                    "$DASHFields{'casename'} (CESM Case Name)",
                    "$case_id (CESM2 Experiments Database ID)"]);
    }
    else {

	# TODO add project specific alternate_identifier's as they become available
	$sql = qq(select name, description from t2_expType where id = $expType_id);
	$sth = $dbh->prepare($sql);
	$sth->execute();
	($DASHFields{'alternate_identifier'}, $DASHFields{'abstract'}) = $sth->fetchrow();
	$sth->finish();
	$DASHFields{'abstract'} = qq($DASHFields{'abstract'} ($DASHFields{'alternate_identifier'}).\n\nUsers can access the data from the Earth System Grid Federation or Climate Data Gateway as registered users; see the \'Related links\' section.\n\nDiagnostic plots are also available from the \'Related links\'.\n\nNCAR users may access the data from Glade; path(s) listed in the \'Additional Information\' section.);
	$DASHFields{'alternate_identifier'} = qq(["$DASHFields{'alternate_identifier'}", 
                    "$DASHFields{'casename'} (CESM Case Name)"],
                    "$case_id (CESM2 Experiments Database ID)"]);
    }

    # get keywords and table info from the t2_DASH_tables except the temporal resolution 
    $sql = qq(select * from t2_DASH_tables where id != 6);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	$table_id = $ref->{'id'};
	$table_name = $ref->{'name'};
	$keyword = $ref->{'keyword'};
	$kw_list = '';

	# build the appropriate join table
	$sql1 = qq(select t.name from $table_name as t, t2j_DASH as j 
                   where j.table_id = $table_id and j.case_id = $case_id and t.id = j.keyword_id);
	$sth1 = $dbh->prepare($sql1);
	$sth1->execute();
	while(my $ref1 = $sth1->fetchrow_hashref())
	{
	    # create a keyword value string depending on the table id
	    $kw_list .= qq("$keyword: $ref1->{'name'}",);
	}
	$sth1->finish();
	$keywords .= $kw_list;
    }
    $sth->finish();

    if (length($keywords) > 0) {
	# chop off trailing ,
	$DASHFields{'keywords'} .= substr($keywords, 0, -1);
	$DASHFields{'keywords'} .= $keywords;
    }
    # append the pre-defined keywords for better searching
    $DASHFields{'keywords'} = qq([$keywords "CESM2", "CESM", "NCAR Community Earth System Model"]);

    # get the temporal resolution (table_id = 6)
    $kw_list = '';
    $sql = qq(select t.name from t2_DASH_temporalResolution as t, t2j_DASH as j 
              where j.table_id = 6 and j.case_id = $case_id and t.id = j.keyword_id);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	# create a keyword value string depending on the table id
	$kw_list .= qq($ref->{'name'};);
    }
    $sth->finish();
    $DASHFields{'temporal_resolution'} = $kw_list;

    # construct the title and additional_information
    # TODO - make sure to get more recent fields from the t2e_fields table
    $sql = qq(select title, compset, grid, machine, DATE_FORMAT(archive_date, '%Y-%m-%d') as archive_date,
              model_version, run_startdate, LEFT(run_lastdate, 10) as run_lastdate
              from t2_cases where id = $case_id);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	$DASHFields{'title'} = qq($ref->{'title'});
	$DASHFields{'title'} =~ s/\r//g;
	# Trim leading and trailing whitespaces
	$DASHFields{'title'} =~ s/^\s+|\s+$//g;
	$compset = $ref->{'compset'};
	$grid = $ref->{'grid'};

	$DASHFields{'additional_information'} = qq(These data were generated by $ref->{'model_version'} on $ref->{'archive_date'} using machine $ref->{'machine'}.\n\nCESM specific information:\n\ncasename = $DASHFields{'casename'}\n\ncase_id =  $case_id\n\ncompset = $compset\n\ngrid = $grid);
	$DASHFields{'resource_version'} = qq($ref->{'model_version'});
	$DASHFields{'run_startdate'} = qq($ref->{'run_startdate'});
	$DASHFields{'run_lastdate'} = qq($ref->{'run_lastdate'});
    }
    $sth->finish();

    # get the public notes to add to the additional_information 
    $sql = qq(select note from t2e_notes where case_id = $case_id and is_public = 1);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	$DASHFields{'additional_information'} = $DASHFields{'additional_information'} . "\n\nNote: " . $ref->{'note'};
    }
    $sth->finish();

    # get the glade path for NCAR users to the single-variable timeseries files, if it exists
    $sql = qq(select p.description, IFNULL(j.disk_path, '')
              from t2_process as p, t2j_status as j
              where j.case_id = $case_id and j.process_id = p.id and j.disk_path is not null and p.id = 3
              order by j.last_update desc limit 1);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my $disk_path = $sth->fetchrow();
    $sth->finish();
    if (length($disk_path) > 0) {
	$DASHFields{'additional_information'} .= qq(\n\nNCAR users can access the native CESM single variable time series files at $disk_path);
    }

    # get dataset size (single variable timeseries to CDG process_id = 20) from t2j_status 
    $sql = qq(select IFNULL(disk_usage, 0) as disk_usage from t2j_status
              where case_id = $case_id and process_id = 20 order by last_update desc limit 1);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my $CDG_size = $sth->fetchrow();
    $sth->finish();

    # get dataset size (single variable conformed ESGF process_id = 18) from t2j_status 
    $sql = qq(select IFNULL(disk_usage, 0) as disk_usage from t2j_status
              where case_id = $case_id and process_id = 18 order by last_update desc limit 1);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my $ESGF_size = $sth->fetchrow();
    $sth->finish();

    # set the asset_size_MB hash element
    if ($CDG_size > 0) {
	$DASHFields{'asset_size_MB'} = sprintf("%.0f", $CDG_size/(1000 * 1000));
    }
    elsif ($ESGF_size > 0) {
	$DASHFields{'asset_size_MB'} = sprintf("%.0f", $ESGF_size/(1000 * 1000));
    }
    else {
	$DASHFields{'asset_size_MB'} = 0;
    }

    # get links to datasets and diags
    $DASHFields{'related_link'} = qq({"name":"Caseroot SVN URL","linkage":"https://svn-cesm2-expdb.cgd.ucar.edu/public/$DASHFields{'casename'}","description":"CESM Caseroot files archive including XML, user namelists and case source modifications."},);
    if ($expType_id == 1) {
	$DASHFields{'related_link'} .= qq({"name":"CMIP6 Data Request","linkage":"http://clipc-services.ceda.ac.uk/dreq/u/$cmip6_exp_uid.html","description":"CMIP6 Data Request Details"},);
    }

    # set the landing page to the ESGF or CDG link or point to SVC page if they don't exist
    $DASHFields{'landing_page'} = qq(https://csegweb.cgd.ucar.edu/experiments/public);

    # load up the related links
    $sql = qq(select p.id, p.description as name, j.link, j.description, 
              DATE_FORMAT(j.last_update, '%Y-%m-%d') as last_update
              from t2j_links as j, t2_process as p 
              where j.case_id = $case_id and j.process_id = p.id 
              order by p.id desc);
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
	if ($ref->{'id'} == 18 || $ref->{'id'} == 20) {
	    $DASHFields{'publication_date'} = $ref->{'last_update'};
	    $DASHFields{'landing_page'} = qq($ref->{'link'});
	}
	$DASHFields{'related_link'} .= qq({"name":"$ref->{'name'}","linkage":"$ref->{'link'}","description":"$ref->{'description'}"},);
	# sterilize it a bit for JSON to ISO
	$DASHFields{'related_link'} =~ s/\s+/ /g;
	$DASHFields{'related_link'} =~ s/\t+/ /g;
	$DASHFields{'related_link'} =~ s/\n+/ /g;
    }
    $sth->finish();

    if (length($DASHFields{'related_link'}) > 0) {
	$DASHFields{'related_link'} = substr($DASHFields{'related_link'}, 0, -1);
	$DASHFields{'related_link'} = qq([$DASHFields{'related_link'}]);
    }
    
    return \%DASHFields;
}

