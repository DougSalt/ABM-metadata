#!/usr/bin/perl
#
# Perl script to create FEARLUS+SPOM parameter files for sources, sinks and
# sustainability book chapter experiments
#
# Updated 2008-02-06 to incorporate changes from Alessandro's document
# dated 2008-01-30.
#
# Version ii for subsequent runs. These have reward per species = half reward
# per activity
#
# Version iii rewards for G3, and not for GL1
#
# Usage:
# ./SSSii-expt.pl <Govt> <Sink> <Market> <BET> <imit> <wealth> <asp> <run>

use strict;

# Usage

my %markets = ( 'flat' => 1,
		'var1' => 2,
		'var2' => 3,
	      );

my $usage = "Usage:\n$0 <Government Class> <Sink (YES or NO)> <Market> ".
  "<Policy Zone> <Reward-Budget> <cluster reward ratio> ".
  "<Break-Even Threshold> <Approval (YES/NO)> ".
  "<Initial Wealth> <Aspiration Threshold> <Run Number>\n\nIf Aspiration ".
  "Threshold is given with a %, then it is a percentage of the BET. If ".
  "Aspiration is \"NO\", then land managers will not make a change of ".
  "land use; care should be taken to ensure that managers cannot make a ".
  "loss in this case.\nMarket ".
  "can be one of ".join(", ", keys(%markets))."\n";

# Experiment setup parameters requiring consistency across several files

my $initsppprob = 1.0;		# Probability that a species will be present
                                # initially on any parcel it can be present

my $maxyear = 200;
my $xsize = 25;
my $ysize = 25;
my $npatches = $xsize * $ysize;
my $nspecies = 10;
my $nhabitat = 6;
my $nlanduse = 6;
my @init_lu_prob = ( 312 / 624,
		     0 / 624,
		     0 / 624,
		     312 / 624,
		     0 / 624,
		     0 / 624 );

# Get options

while($ARGV[0] =~ /^-/) {
  my $option = shift(@ARGV);

    die "Unrecognised option $option. $usage";
}

# Get arguments

die "$usage" unless scalar(@ARGV) == 11;

my $govt = shift(@ARGV);
my $sink = shift(@ARGV);
my $market = shift(@ARGV);
my $arg_zone = shift(@ARGV);
my $arg_reward = shift(@ARGV);
my $arg_budget = "1.0";
my $cluster_ratio = shift(@ARGV);
my $activity_divisor = 1;
my $bet = shift(@ARGV);
my $approval = shift(@ARGV);
my $iwealth = shift(@ARGV);
my $aspiration = shift(@ARGV);
my $run = shift(@ARGV);

if($aspiration =~ /%$/) {
  $aspiration =~ s/%$//;
  $aspiration *= $bet / 100.0;
}

if($arg_reward =~ /^(.+)-(.+)$/) {
  $arg_reward = $1;
  $arg_budget = $2;
}

# Check the arguments have sensible values and confirm them back to the
# user

my %nonbudgetablegovtclasses
  = ( 'NbrSubsetActivityGovernment' => ["LandUse:Reward", "MinNNeighbours",
					"MaxNRewards"],
      'NbrSubsetSpeciesGovernment' => ["Species:Reward", "MinNNeighbours",
				       "MaxNRewards"],
      'SortNbrSubsetActivityGovernment' => ["LandUse:Reward", "MinNNeighbours",
					    "MaxNRewards"],
      'SortNbrSubsetSpeciesGovernment' => ["Species:Reward", "MinNNeighbours",
					   "MaxNRewards"],
      'SortSubsetActivityGovernment' => ["LandUse:Reward", "MaxNRewards"],
      'SortSubsetSpeciesGovernment' => ["Species:Reward", "MaxNRewards"],
      'SubsetActivityGovernment' => ["LandUse:Reward", "MaxNRewards"],
      'SubsetSpeciesGovernment' => ["Species:Reward", "MaxNRewards"],
      'NoGovernment' => []);
my %budgetablegovtclasses
  = ( 'ClusterActivityGovernment' => ["LandUse", "Reward", "NbrReward"],
      'ClusterSpeciesGovernment' => ["Species", "Reward", "NbrReward"],
      'RewardActivityGovernment' => ["LandUse:Reward",],
      'RewardSpeciesGovernment' => ["Species:Reward",],
      'TargetActivityGovernment' => ["LandUse:Target", "Reward"],
      'TargetSpeciesGovernment' => ["Species:Target", "Reward"],
      'TargetClusterActivityGovernment' => ["LandUse:Target", "Reward",
					    "NbrReward"],
      'TargetClusterSpeciesGovernment' => ["Species:Target", "Reward",
					   "NbrReward"]);
my %govtclasses;
my @govtparam;
if($govt !~ /Government$/) {
  $govt = $govt.'Government';
}
@govtparam = ("Zone") if $govt ne 'NoGovernment';

foreach my $nonbudgetgovt (keys(%nonbudgetablegovtclasses)) {
  $govtclasses{$nonbudgetgovt} = 1;
  if($govt eq $nonbudgetgovt) {
    push(@govtparam, @{$nonbudgetablegovtclasses{$nonbudgetgovt}});
  }
}
foreach my $budgetgovt (keys(%budgetablegovtclasses)) {
  $govtclasses{$budgetgovt} = 1;
  if($govt eq $budgetgovt) {
    push(@govtparam, @{$budgetablegovtclasses{$budgetgovt}});
  }
  foreach my $prefix ('Budget', 'Capped', 'CappedBudget') {
    my $newclass = $prefix.$budgetgovt;
    $govtclasses{$newclass} = 1;
    if($govt eq $newclass) {
      push(@govtparam, @{$budgetablegovtclasses{$budgetgovt}});
      push(@govtparam, "Cap") if $prefix =~ /Capped/;
      push(@govtparam, "Budget") if $prefix =~ /Budget/;
    }
  }
}

if(!defined($govtclasses{$govt})) {
  die "Invalid value for Government Class: $govt. It must be one of "
    .join(", ", keys(%govtclasses))." (you don't have to specify the final "
    ."\"Government\" if you don't want)\n";
}

foreach my $yesno ([\$sink, 'Sink'],
		   [\$approval, 'Approval']) {
  my ($yn, $txt) = @{$yesno};

  if($$yn =~ /^YES$/i) {
    $$yn = "yes";
  }
  elsif($$yn =~ /^NO$/i) {
    $$yn = "no";
  }
  else {
    die "Invalid value for $txt: $$yn. It must be YES or NO\n";
  }
}

if(!defined($markets{$market})) {
  die "Invalid value for Market: $market. It must be one of "
    .join(", ", keys(%markets))."\n";
}

foreach my $param_txt ([$bet, 'Break-Even Threshold'],
		       [$arg_reward, 'Reward'],
		       [$cluster_ratio, 'Cluster'],
		       [$arg_budget, 'Budget'],
		       [$iwealth, 'Initial Wealth'],
		       [$aspiration, 'Aspiration Threshold']) {
  my ($param, $txt) = @$param_txt;

  if($txt eq 'Aspiration Threshold' && $param =~ /NO/i) {
    $aspiration = 'no';
  }
  else {
    if($param !~ /^[0-9]+(\.[0-9]+)?$/) {
      die "Illegal value for $txt: $param. It must be a non-negative float.\n";
    }
    if($txt =~ /^Probability/
       && ($param < 0.0 || $param > 1.0)) {
      die "Illegal value for $txt: $param. It must be in the range [0, 1].\n";
    }
  }
  print "$txt: $param\n";
}

if($aspiration eq 'no' && $bet > 0.0) {
  die "Aspiration Threshold set to \"no\", but BET ($bet) is > 0.0\n";
}

if($run !~ /^\d+/) {
  die "Run number $run should be an integer.\n";
}
$run = sprintf("%03d", $run);
print "Run: $run\n";


# Handle government parameters

my $maxnrewards = 100;
my $minnneighbours = 2;
my $reward = $arg_reward;
my $nbrreward = $reward / $cluster_ratio;
$reward = $nbrreward if $govt =~ /^(Target)?Cluster/;
my $budget = $reward * $xsize * $ysize / $arg_budget;
my $cap = $reward * 4.0;
my @zone;

if($arg_zone eq 'all') {
  push(@zone, 'all');
}
elsif($arg_zone eq 'random') {
  push(@zone, '50%');
}
elsif($arg_zone eq 'rect') {
  push(@zone, "[".int($xsize / 4).",".int($ysize / 4)."|"
       .(3 * int($xsize / 4)).",".(3 * int($ysize / 4))."]");
}
else {
  die "Invalid value for zone argument: $arg_zone\n";
}

my $spp_reward = $reward / $activity_divisor;

my %landuse_reward = ( "GL1" => "no",
		       "GL2" => "$reward",
		       "GL3" => "no",
		       "AL1" => "$reward",
		       "AL2" => "no",
		       "AL3" => "no" );
my %landuse_target = ( "GL1" => "25%",
		       "GL2" => "25%",
		       "GL3" => "no",
		       "AL1" => "25%",
		       "AL2" => "no",
		       "AL3" => "no" );
my %species_reward = ( "G1" => "no",
		       "G2" => "no",
		       "G3" => "$spp_reward",
		       "G4" => "no",
		       "G5" => "$spp_reward",
		       "G6" => "$spp_reward",
		       "A1" => "no",
		       "A2" => "$spp_reward",
		       "A3" => "$spp_reward",
		       "C2" => "no" );
my %species_target = ( "G1" => "no",
		       "G2" => "no",
		       "G3" => "no",
		       "G4" => "no",
		       "G5" => "30%",
		       "G6" => "30%",
		       "A1" => "no",
		       "A2" => "30%",
		       "A3" => "30%",
		       "C2" => "no" );

my %allgovparams = ( "Zone" => \@zone,
		     "MaxNRewards" => [$maxnrewards],
		     "MinNNeighbours" => [$minnneighbours],
		     "Reward" => [$reward],
		     "NbrReward" => [$nbrreward],
		     "Budget" => [$budget],
		     "Cap" => [$cap] );

# Relate the parameters to the files. This is given as an associative
# array with the file type pointing to an array containing in position
# 1, a list of parameters that affect the uniqueness of the file, in
# position 2, a list of file types the names of which are referred to
# in the file, and in position 3, a suffix for the file. Before that, we
# need another associative array of all the parameters and their values
# so they can be put in order

my $sinktxt = $sink eq 'yes' ? 'sink' : 'nosink';
my $approvaltxt = $approval eq 'yes' ? 'approval' : 'noapproval';
my $govttxt = $govt;
$govttxt =~ s/Government$//;
my $aspirationtxt = $aspiration eq 'no' ? 'noaspiration' : $aspiration;

my %param_values
  = ( 'government' => $govttxt,
      'sink' => $sinktxt,
      'market' => $market,
      'zone' => $arg_zone,
      'reward' => $arg_budget == 1.0 ? $arg_reward : "$arg_reward-$arg_budget",
      'cluster' => $cluster_ratio,
      'bet' => $bet,
      'approval' => $approvaltxt,
      'iwealth' => $iwealth,
      'aspiration' => $aspirationtxt,
      'run' => $run );

my %param_file
  = ( 'dir' => [['government', 'sink', 'zone', 'reward', 'cluster', 'market',
		 'bet', 'approval', 'iwealth', 'aspiration'], [], ''],
      'top-level' => [[], ['fearlus', 'spom'], '.model'],
      'spom' => [['sink'], ['species', 'patch', 'luhab', 'sink'], '.spom'],
      'spomresult' => [['run'], ['top-level'], ''],
      'luhab' => [[], [], '.csv'],
      'species' => [['sink'], [], '.csv'],
      'sink' => [['sink'], [], '.csv'],
      'patch' => [['run'], ['luhab', 'species', 'sink'], '.csv'],
      'dummy' => [[], [], ''],
      'fearlus' => [['bet', 'government'],
		    ['yieldtree', 'yielddata', 'incometree', 'incomedata',
		     'climateprob', 'economystate', 'economyprob',
		     'government', 'top-level subpop', 'grid'], '.fearlus'],
      'top-level subpop' => [[], ['subpop'], '.ssp'],
      'subpop' => [['approval', 'iwealth', 'aspiration'],
		   ['trigger', 'event'], '.sp'],
      'event' => [['approval'], [], '.event'],
      'trigger' => [['approval'], [], '.trig'],
      'climateprob' => [[], [], '.prob'],
      'economyprob' => [[], [], '.prob'],
      'economystate' => [['market'], [], '.state'],
      'incometree' => [['market'], [], '.tree'],
      'incomedata' => [['market'], [], '.data'],
      'yieldtree' => [[], [], '.tree'],
      'yielddata' => [[], [], '.data'],
      'grid' => [['run'], ['luhab'], '.grd'],
      'government' => [['government', 'reward', 'cluster', 'zone'], [], '.gov'],
      'report' => [['run'], ['top-level'], '.txt'],
      'report config' => [['run'], ['top-level'], '.repcfg']);

# Prepare the filenames and the name of the directory. The directory name
# consists of all the parameters, except the run number (so, one directory
# contains a series of runs, the parameters of which are the same). All file
# names (including the directory name) consist of the values of parameters
# that affect them (either directly or through files they point to),
# in a specific order (@param_order array), with underscores separating
# *all* parameters, including those not affecting the file (which are
# included as empty values). Thus those files not affected by many parameters
# will thus have several consecutive underscores in their names.

my $prefix = 'SSS_';

my @param_order = ( 'sink', 'government', 'zone', 'reward', 'cluster', 'market',
		    'bet', 'approval', 'iwealth', 'aspiration', 'run' );

my %param_name;

foreach my $pf (keys(%param_file)) {
  my ($params, $files, $suffix) = @{$param_file{$pf}};

  my %file_params;

  foreach my $p (@$params) {
    $file_params{$p} = $p;
  }

  my @filestack = @$files;
  while(my $file = shift(@filestack)) {
    if(!defined($param_file{$file})) {
      die "No definition for file $file found in %param_file\n";
    }

    my ($fparams, $ffiles, $fsuffix) = @{$param_file{$file}};

    foreach my $p (@$fparams) {
      $file_params{$p} = $p;
    }
    push(@filestack, @$ffiles);
  }

  my $filename = $prefix.$pf;

  $filename =~ s/ /-/g;

  for(my $i = 0; $i <= $#param_order; $i++) {
    if(defined($file_params{$param_order[$i]})) {
      $filename .= "_$param_values{$param_order[$i]}";
    }
    else {
      $filename .= "_";
    }
  }
  $filename .= $suffix;

  $param_name{$pf} = $filename;
}

# Assign the filenames to relevant variables

my $dir = $param_name{'dir'};
if(!-e "$dir") {
  mkdir($dir, 0777) || die "Cannot create directory $dir: $!\n";
}
elsif(!-d "$dir") {
  die "Experiment subdirectory name $dir exists, but not as a directory\n";
}
chdir($dir) || die "Cannot change cwd to $dir: $!\n";

my $modelfile = $param_name{'top-level'};
my $spomfile = $param_name{'spom'};
my $spomResultStem = $param_name{'spomresult'};
my $dummyspomfilestem = $param_name{'dummy'};
my $ndummyspomfilestem = 7;	# Change habitat file
				# Autocorrelated field file
				# Good bad year file
				# Localised field file
				# Predation file
				# Habitat-specific mu file
				# Occupied patches per species output file

my $fearlusfile = $param_name{'fearlus'};
my $patchfile = $param_name{'patch'};
my $speciesfile = $param_name{'species'};
my $sinkfile = $param_name{'sink'};
my $sspfile = $param_name{'top-level subpop'};
my $spfile = $param_name{'subpop'};
my $eventfile = $param_name{'event'};
my $triggerfile = $param_name{'trigger'};
my $climateprobfile = $param_name{'climateprob'};
my $economyprobfile = $param_name{'economyprob'};
my $economystatefile = $param_name{'economystate'};
my $yieldtreefile = $param_name{'yieldtree'};
my $yielddatafile = $param_name{'yielddata'};
my $incometreefile = $param_name{'incometree'};
my $incomedatafile = $param_name{'incomedata'};
my $gridfile = $param_name{'grid'};
my $luhabfile = $param_name{'luhab'};
my $repcfgfile = $param_name{'report config'};
my $reportfile = $param_name{'report'};
my $govtfile = $param_name{'government'};

# Now create the files, using heredocs

#################################################################### Model File

open(MODEL, ">$modelfile") || die "Cannot create model file $modelfile: $!\n";
print MODEL <<MODEL_END;
\@begin
envXSize	        $xsize
envYSize		$ysize

nSpecies		$nspecies
nLandUse		$nlanduse

maxYear			$maxyear

fearlusParamFile	$fearlusfile
spomParamFile		$spomfile
\@end
MODEL_END
close(MODEL);
print "Created model file $modelfile\n";

##################################################################### SPOM File

open(SPOM, ">$spomfile") || die "Cannot create SPOM file $spomfile: $!\n";
print SPOM <<SPOM_END;
\@begin
connectClass					SPOMConnect1
dispersalClass					SPOMDispersal1
distanceClass					SPOMToroidalDistance
colonizationClass				SPOMColonization1
extinctionClass					SPOMExtinction1
rescueEffectParameter				1
preOccupancyEffect                              1
preOccupancyEffectnSteps                        0
enableHabitatSpecificMu                         no
enableSinkHabitats                              $sink
competition					yes
predation					no
predationAffectingPrays				no
spatialSubsidiesAffectingCompetitiveExclusion	no
AcellPredationInfluence				1
advancedSeedDispersal				no
 
nPatches					$npatches
nHabitat					$nhabitat

Acell						1
xparam						1
yparam						1

patchFile					$patchfile
speciesFile					$speciesfile
propResultFile					$spomResultStem-prop.csv
exctinctionFile					$spomResultStem-extinct.csv

nbSpeciesFile					$spomResultStem-nspp.csv
nStepNbSpecies					10
listSpeciesFile					$spomResultStem-lspp.csv
speciesPerPatchFile				$spomResultStem-pspp.csv
nStepListSpecies				10
areaCurveFile					$spomResultStem-area.csv
nStepAreaCurve					2
nIterAreaCurve					3
areaCurveLength					10
changeHabitatFile				$dummyspomfilestem-1.csv
nStepChangeHabitat				1
nChangeHabitat					$maxyear
enableRegionalStochasticityAtStep		0
nStepUsingRegionalStochasticity			2
enableHabitatSpecific				0
autoCorrelatedFieldFile				$dummyspomfilestem-2.csv
goodBadYearFile					$dummyspomfilestem-3.csv
csvLocalizedField_file				$dummyspomfilestem-4.csv
landUseHabitatFile				$luhabfile
predationFile                                   $dummyspomfilestem-5.csv
habitatGridOuptutFile				$spomResultStem-habgrid.csv
nStepOutputHabitat				10
HabitatPresentThreshold				0.2
habitatSpecificMuFile                           $dummyspomfilestem-6.csv
sinkHabitatPropertieFile                        $sinkfile
occupiedPatchesPerSpeciesOutputFile             $dummyspomfilestem-7.csv
\@end
SPOM_END
close(SPOM);
print "Created SPOM file $spomfile\n";

################################################## Land use habitat matrix file

open(LUHAB, ">$luhabfile")
  || die "Cannot create land use/habitat matrix file $luhabfile: $!\n";
print LUHAB <<LUHAB_END;
Land Use,GH1,GH2,GH3,AH1,AH2,AH3
1,1,0,0,0,0,0
2,0.2,0.8,0,0,0,0
3,0,0,1,0,0,0
4,0,0,0,1,0,0
5,0,0,0,0,1,0
6,0,0,0,0,0,1
LUHAB_END
close(LUHAB);
print "Created land use/habitat matrix file $luhabfile\n";

################################################################## Species file

my $h = $sink eq 'yes' ? 1 : 1;	# Don't know if sink => put 1 for hab.
                                # 0 : 0 means you don't, 1 : 0 means you do,
                                # and don't want the habitat enabled when there
                                # are no sinks, 1 : 1 means you do, and do
open(SPECIES, ">$speciesfile")
  || die "Cannot create species file $speciesfile: $!\n";
print SPECIES <<SPECIES_END;
Name of species,C,B,ALPHA,MU,BETA,Seed C1,Seed C2,GH1,GH2,GH3,AH1,AH2,AH3,G1,G2,G3,G4,G5,G6,A1,A2,A3,C2
G1,1,1,0.8,0.1,1,0.0,0.0,01,01,01,00,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
G2,1,1,0.9,0.1,1,0.0,0.0,01,01,01,00,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
G3,1,1,1.1,0.1,1,0.0,0.0,01,01,01,00,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
G4,1,1,1.3,0.1,1,0.0,0.0,01,01,00,00,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
G5,1,1,1.3,0.1,1,0.0,0.0,01,01,00,$h,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
G6,1,1,1.3,0.1,1,0.0,0.0,01,00,00,$h,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
A1,1,1,1.3,0.1,1,0.0,0.0,00,00,00,01,01,01,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
A2,1,1,0.9,0.1,1,0.0,0.0,00,$h,00,01,01,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
A3,1,1,0.8,0.1,1,0.0,0.0,00,$h,00,01,00,00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
C2,1,1,1.3,0.05,1,0.0,0.0,01,00,00,00,00,00,+3,+3,+3,-1,-1,-1,-1,-1,-1,-1
SPECIES_END
close(SPECIES);
print "Created species file $speciesfile\n";

##################################################################### Sink file

my $s = $sink eq 'yes' ? 1 : 0;
open(SINK, ">$sinkfile") || die "Cannot create sink file $sinkfile: $!\n";
print SINK <<SINK_END;
Hab,G1,G2,G3,G4,G5,G6,A1,A2,A3,C2
GH1,00,00,00,00,00,00,00,00,00,00
GH2,00,00,00,00,00,00,00,$s,$s,00
GH3,00,00,00,00,00,00,00,00,00,00
AH1,00,00,00,00,$s,$s,00,00,00,00
AH2,00,00,00,00,00,00,00,00,00,00
AH3,00,00,00,00,00,00,00,00,00,00
SINK_END
close(SINK);
print "Created sink file $sinkfile\n";

###############################################################################
#
# Randomise the land use, patch and initial species distribution file
#
###############################################################################

my %patchhab;			# Patch number -> [habitat values...]
my %patchspp;			# Patch number -> [species values...]
my %patchlu;			# Patch number -> landuse
my %coordpatch;			# Patch x, y -> patch number
my %luhab;			# Land use number -> [hab values...]
my %habspp;			# Habitat name -> [species values...]
my @habs;			# Habitat names
my @spps;			# Species names

# Read the land use/habitat file and populate %luhab and @habs

open(LUHAB, "<$luhabfile")
  || die "Cannot read land use/habitat matrix file $luhabfile: $!\n";
my $line = <LUHAB>;
chomp $line;
@habs = split(/,/, $line);
shift @habs;
for(my $i = 1; $i <= $nlanduse; $i++) {
  my $line;

  if(!($line = <LUHAB>)) {
    die "Unexpected end of file reading land use/habitat matrix file "
      ."$luhabfile for land use $i\n";
  }
  chomp $line;

  my @lh = split(/,/, $line);

  my $lu = shift @lh;
  if($lu < 1 || $lu > $nlanduse || $lu !~ /^\d+$/) {
    die "Invalid land use ID $lu in land use/habitat matrix file $luhabfile\n";
  }

  $luhab{$lu} = [];
  for(my $j = 0; $j <= $#lh; $j++) {
    push(@{$luhab{$lu}}, $lh[$j]);
  }
}
close(LUHAB);

# Read the species file and populate %habspp and @spps

open(SPECIES, "<$speciesfile")
  || die "Cannot read species file $speciesfile: $!\n";
$line = <SPECIES>;
chomp $line;
{
  my @cells = split(/,/, $line);

  shift @cells;			# species name
  shift @cells;			# C
  shift @cells;			# B
  shift @cells;			# Alpha
  shift @cells;			# Mu
  shift @cells;			# Beta
  shift @cells;			# Seed C1
  shift @cells;			# Seed C2

  for(my $i = 0; $i <= $#habs; $i++) {
    if($cells[$i] ne $habs[$i]) {
      die "Mismatch in habitats in species file $speciesfile and land use/"
	."habitat matrix file $luhabfile. Habitat ".($i + 1)." is $cells[$i] "
	."in the species file, but $habs[$i] in the matrix file\n";
    }
  }
}
while($line = <SPECIES>) {
  chomp $line;

  my @cells = split(/,/, $line);

  push(@spps, shift @cells);

  shift @cells;			# C
  shift @cells;			# B
  shift @cells;			# Alpha
  shift @cells;			# Mu
  shift @cells;			# Beta
  shift @cells;			# Seed C1
  shift @cells;			# Seed C2

  for(my $j = 0; $j <= $#habs; $j++) {
    $habspp{$habs[$j]} = [] if !defined($habspp{$habs[$j]});
    push(@{$habspp{$habs[$j]}}, $cells[$j]);
#    print "Species $spps[$#spps] on habitat $habs[$j]: $cells[$j]\n";
  }
}

close(SPECIES);

if(scalar(@spps) != $nspecies) {
  die "Number of species in species file ".scalar(@spps)." is not consistent "
    ."with expected number of species $nspecies\n";
}

# Read the sink file and add to %habspp where species can exist as sinks

open(SINK, "<$sinkfile") || die "Cannot read sink file $sinkfile: $!\n";

$line = <SINK>;
chomp $line;

{
  my @cells = split(/,/, $line);

  shift(@cells);

  if(scalar(@cells) != scalar(@spps)) {
    die "There are a different number of species in the species file and "
      ."the sink file\n";
  }

  for(my $i = 0; $i <= $#cells; $i++) {
    if($cells[$i] ne $spps[$i]) {
      die "Species ".($i + 1)." is $cells[$i] in the sink file, but $spps[$i] "
	."in the species file\n";

    }
  }
}

for(my $i = 0; $i <= $#habs; $i++) {
  my $line;

  if(!($line = <SINK>)) {
    die "Unexpected end of file reading sink file $sinkfile for habitat "
      ."$habs[$i]\n";
  }

  chomp $line;

  my @cells = split(/,/, $line);

  my $this_hab = shift @cells;

  if($this_hab ne $habs[$i]) {
    die "Habitat ".($i + 1)." is $this_hab in the sink file $sinkfile, but "
      ."$habs[$i] in other files\n";
  }

  for(my $j = 0; $j <= $#spps; $j++) {
    if($cells[$j] == 1) {
      ${$habspp{$habs[$i]}}[$j] = 1;
#      print "Species $spps[$j] sink on habitat $habs[$i]\n";
    }
  }
}
close(SINK);

# Now create the initial land use, habitat and species locations and populate
# %coordpatch, %patchlu, %patchhab and %patchspp

# Use random initial distribution, non-uniform... From previous experiments
# with the SPOM, we need 200 GL1, 56 GL2, 56 GL3, 104 AL1, 104 AL2 and 104
# AL3, with the remaining parcel random.

my @cumul_lu_prob;
$cumul_lu_prob[0] = $init_lu_prob[0];
for(my $i = 1; $i <= $#init_lu_prob; $i++) {
  $cumul_lu_prob[$i] = $cumul_lu_prob[$i - 1] + $init_lu_prob[$i];
}

for(my $i = 0; $i < $ysize * $xsize; $i++) {
  my $x = $i % $xsize;
  my $y = int($i / $xsize);

  $coordpatch{$x, $y} = $i;

  my $rnd = rand();

  my $lu;
  for(my $j = 0; $j <= $#cumul_lu_prob; $j++) {
    if($rnd < $cumul_lu_prob[$j]) {
      $lu = $j + 1;
      last;
    }
  }

  $patchlu{$i} = $lu;
}

# Before populating the habitates and species (%patchhab and %patchspp),
# clump the land uses

# Do not clump the land uses!

my $clump = 0;			# Change this to 1 --> clump; 0 --> don't

my $last_ncells = -1;
while($clump) {
  $clump = 0;
  my $ncells = 0;
  for(my $x = 0; $x < $xsize; $x++) {
    for(my $y = 0; $y < $ysize; $y++) {
      my $i = $coordpatch{$x, $y};

      my $sim_i_stay = &similar($patchlu{$i}, $x, $y, $xsize, $ysize,
				\%patchlu, \%coordpatch);

      my $max_diff = 0;

      my @max_diff_xy = ([$x, $y]);

      # Find a patch to swap with that makes the maximum difference in
      # the similarity of a patch with its neighbours

      for(my $xx = 0; $xx < $xsize; $xx++) {
	for(my $yy = 0; $yy < $ysize; $yy++) {
	  my $j = $coordpatch{$xx, $yy};

	  next if $i == $j;

	  my $sim_j_stay = &similar($patchlu{$j}, $xx, $yy, $xsize, $ysize,
				    \%patchlu, \%coordpatch);
	  my $sim_i_move = &similar($patchlu{$i}, $xx, $yy, $xsize, $ysize,
				    \%patchlu, \%coordpatch);
	  my $sim_j_move = &similar($patchlu{$j}, $x, $y, $xsize, $ysize,
				    \%patchlu, \%coordpatch);

	  my $diff = ($sim_i_move + $sim_j_move) - ($sim_i_stay + $sim_j_stay);

	  if($diff > $max_diff) {
	    @max_diff_xy = ([$xx, $yy]);
	    $max_diff = $diff;
	  }
	  elsif($diff > 0 && $diff == $max_diff) {
	    push(@max_diff_xy, [$xx, $yy]);
	  }

#	  print "Swap ($x, $y) and ($xx, $yy): difference $diff\n";
	}
      }

      # Make the swap

      if($max_diff > 0) {
	my ($max_diff_x, $max_diff_y)
	  = @{$max_diff_xy[int(rand(scalar(@max_diff_xy)))]};
	my $j = $coordpatch{$max_diff_x, $max_diff_y};
	my $tmp_lu = $patchlu{$i};
	$patchlu{$i} = $patchlu{$j};
	$patchlu{$j} = $tmp_lu;
	$clump = 1;
#	print "Swapping ($x, $y) and ($max_diff_x, $max_diff_y)\n";
	$ncells++;
      }
    }
  }
  print "Made $ncells swaps\n";
  last if $last_ncells == $ncells;
  $last_ncells = $ncells;
}

# Populate the habitats and species

for(my $i = 0; $i < $ysize * $xsize; $i++) {
  my $lu = $patchlu{$i};
  my @habvals = @{$luhab{$lu}};
  if(scalar(@habvals) != scalar(@habs)) {
    die "For land use $lu, we have ".scalar(@habvals)." habitat values, but "
      .scalar(@habs)." habitats\n";
  }
  $patchhab{$i} = [];
  my @pspps;
  for(my $j = 0; $j <= $#habs; $j++) {
    push(@{$patchhab{$i}}, $habvals[$j]);

    my @thisspp = @{$habspp{$habs[$j]}};

    for(my $k = 0; $k <= $#spps; $k++) {
      $pspps[$k] = 0 if !defined($pspps[$k]);

      if($pspps[$k] != 1) {
	if($habvals[$j] > 0.0 && $thisspp[$k] == 1 && rand() < $initsppprob) {
	  $pspps[$k] = 1;
	}
      }
    }
  }
  $patchspp{$i} = [];
  for(my $k = 0; $k <= $#spps; $k++) {
    push(@{$patchspp{$i}}, $pspps[$k]);
  }
}
    

#################################################################### Patch file

open(PATCHES, ">$patchfile")
  || die "Cannot create patch file $patchfile: $!\n";

print PATCHES "Patch number,".join(",", @habs).",".join(",", @spps)."\r\n";
for(my $i = 0; $i < $xsize * $ysize; $i++) {
  my @phab = @{$patchhab{$i}};
  my @pspp = @{$patchspp{$i}};
  print PATCHES ($i + 1).",".join(",", @phab).",".join(",", @pspp)."\r\n";
}

close(PATCHES);
print "Created patch file $patchfile\n";

############################################################## Dummy SPOM files

for(my $i = 1; $i <= $ndummyspomfilestem; $i++) {
  open(DUMMYSPOM, ">$dummyspomfilestem-$i.csv")
    || die "Cannot create dummy SPOM file $dummyspomfilestem-$i.csv: $!\n";
  print DUMMYSPOM "A dummy file that should not get used, but the absence of "
    ."which nonetheless upsets the SPOM.\n";
  close(DUMMYSPOM);
  print "Created dummy SPOM parameter file $dummyspomfilestem-$i.csv\n";
}

################################################################## FEARLUS file

open(FEARLUS, ">$fearlusfile")
  || die "Cannot open FEARLUS file $fearlusfile: $!\n";
print FEARLUS <<FEARLUS_END;
\@begin
environmentType		Toroidal-Moore
neighbourhoodRadius	1

climateGroupName	Climate
economyGroupName	Economy
landUseGroupName	LandUse
biophysGroupName	Biophysical

yieldTreeFile		$yieldtreefile
yieldTableFile		$yielddatafile

incomeTreeFile		$incometreefile
incomeTableFile		$incomedatafile

clumping		None
climateChangeProbFile	$climateprobfile

economyFile		$economystatefile
economyChangeProbFile	$economyprobfile

useClimateFile		0
useEconomyFile		1
useLandUseFile		0

infiniteTime		0

pollutionDist		uniform
pollutionMin		0.0
pollutionMax		0.0

cellArea		1.0
xCellsPerParcel		1
yCellsPerParcel		1
xllcorner		0.57
yllcorner		850.4
gridFile		$gridfile
useGridFile		1
nodata_value		-9999
subPopFile		$sspfile
breakEvenThreshold	$bet
farmScaleFixedCosts	0.0
vickrey			0
allowEstateGrowth	1
socialNeighbourSales    0
nInitXParcels		1
nInitYParcels		1

governmentClass		$govt
governmentFile          $govtfile
\@end
FEARLUS_END
close(FEARLUS);
print "Created FEARLUS file $fearlusfile\n";

###################################################### Subpopulation array file

open(SSP, ">$sspfile")
  || die "Cannot open subpopulation array file $sspfile: $!\n";
print SSP <<SSP_END;
NumberOfSubPopulations: 1
ClassForSubPopulations: CBRDelayedChangeSubPopulation
SubPopulationFile 1: $spfile Probability: 1.0
SSP_END
close(SSP);
print "Created subpopulation array file $sspfile\n";

############################################################ Subpopulation file

my ($social_aspiration, $salience_margin, $salience_adjust, $approval_minsal)
  = ($approval eq 'yes') ? (0.5, 99.0, 1.0, 1.0) : (0.0, 0.0, 0.0, 0.0000001);
my $p_cbr = $aspiration eq 'no' ? 0.0 : 1.0;
$aspiration = $aspiration eq 'no' ? 0.0 : $aspiration;
open(IMITSP, ">$spfile")
  || die "Cannot create imitator subpopulation file $spfile: $!\n";
print IMITSP <<IMITSP_END;
\@begin
label				CBRDelayedChange
landManagerClass		CBRDelayedChangeLandManager
initialAccountDist		uniform
initialAccountMin		$iwealth
initialAccountMax		$iwealth
biddingStrategyClass		FixedPriceBiddingStrategy
biddingStrategyConfig		priceDist=uniform;priceMin=20.0;priceMax=20.0
selectionStrategyClass		RandomSelectionStrategy
incomerPriceDist		uniform
incomerPriceMin			20.0
incomerPriceMax			20.0
landOfferDist			uniform
landOfferMin			40.0
landOfferMax			40.0
offFarmIncomeMeanMin		0.0
offFarmIncomeMeanMax		0.0
offFarmIncomeVarMin		0.0
offFarmIncomeVarMax		0.0
pSellUpDist                     uniform
pSellUpMin                      0.0
pSellUpMax                      0.0
triggerFile                     $triggerfile
eventFile                       $eventfile
profitMinSalienceDist           uniform
profitMinSalienceMin            1.0
profitMinSalienceMax            1.0
approvalMinSalienceDist         uniform
approvalMinSalienceMin          $approval_minsal
approvalMinSalienceMax          $approval_minsal
salienceMarginDist              uniform
salienceMarginMin               $salience_margin
salienceMarginMax               $salience_margin
salienceAdjustDist              uniform
salienceAdjustMin               $salience_adjust
salienceAdjustMax               $salience_adjust
profitAspirationDist            uniform
profitAspirationMin             $aspiration
profitAspirationMax             $aspiration
approvalAspirationDist          uniform
approvalAspirationMin           $social_aspiration
approvalAspirationMax           $social_aspiration
pCBRDist                        uniform
pCBRMin                         $p_cbr
pCBRMax                         $p_cbr
pImitateDist                    uniform
pImitateMin                     0.0
pImitateMax                     0.0
memorySizeMin                   1
memorySizeMax                   1
changeDelayMin                  1
changeDelayMax                  9
imitativeStrategy               NoStrategy
experimentationStrategy         NoStrategy
CBTimeLimitMin                  75
CBTimeLimitMax                  75
CBSizeLimitMin                  0
CBSizeLimitMax                  0
adviceStrategy                  NoDisapproverAdviceStrategy
\@end
IMITSP_END
close(IMITSP);
print "Created subpopulation file $spfile\n";

#################################################################### Event file

open(EVENT, ">$eventfile") || die "Cannot create event file $eventfile: $!\n";
if($approval eq 'yes') {
print EVENT <<EVENT_END;
BEGIN EVENT NetLossEvent
  Response: incProfitSalience
END
BEGIN EVENT DisapprovalProportionEvent
  Response: incApprovalSalience
  DisapprovalThreshold: 0.5
END
EVENT_END
close(EVENT);
}
print "Created event file $eventfile\n";

################################################################## Trigger file

open(TRIGGER, ">$triggerfile")
  || die "Cannot create trigger file $triggerfile: $!\n";
if($approval eq 'yes') {
  print TRIGGER <<TRIGGER_END;
BEGIN TRIGGER LandUseGroupTrigger
  Approval: 1.0
  Disapproval: 0.0
  LandUseSymbols: LandUse/GL1
END
BEGIN TRIGGER LandUseGroupTrigger
  Approval: 1.0
  Disapproval: 0.0
  LandUseSymbols: LandUse/AL1
END
BEGIN TRIGGER LandUseGroupTrigger
  Approval: 0.0
  Disapproval: 1.0
  LandUseSymbols: LandUse/GL3
END
BEGIN TRIGGER LandUseGroupTrigger
  Approval: 0.0
  Disapproval: 1.0
  LandUseSymbols: LandUse/AL3
END
TRIGGER_END
}
close(TRIGGER);
print "Created trigger file $triggerfile\n";

###################################################### Climate probability file

open(CLIMATEPROB, ">$climateprobfile")
  || die "Cannot create climate change probability file "
    ."$climateprobfile: $!\n";
print CLIMATEPROB <<CLIMATEPROB_END;
NumberOfElements: 1
d 0.0
CLIMATEPROB_END
close(CLIMATEPROB);
print "Created climate change probability file $climateprobfile\n";

###################################################### Economy probability file

open(ECONOMYPROB, ">$economyprobfile")
  || die "Cannot create economy change probability file "
    ."$economyprobfile: $!\n";
print ECONOMYPROB <<ECONOMYPROB_END;
NumberOfElements: 1
d 0.01
ECONOMYPROB_END
close(ECONOMYPROB);
print "Created economy change probability file $economyprobfile\n";

############################################################ Economy state file

open(ECONOMYSTATE, ">$economystatefile")
  || die "Cannot create economy state time-series file "
    ."$economystatefile: $!\n";
if($markets{$market} == 1) {	# flat
  for(my $i = 0; $i <= $maxyear; $i++) {
    print ECONOMYSTATE "{State1}\n";
  }
}
elsif($markets{$market} == 2) {	# var1
  print ECONOMYSTATE <<ECONOMYSTATE_END;
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State5}
{State21}
{State22}
{State23}
{State24}
{State25}
{State26}
{State8}
{State27}
{State28}
{State15}
{State29}
{State30}
{State31}
{State32}
{State16}
{State33}
{State34}
{State7}
{State35}
{State24}
{State36}
{State37}
{State23}
{State38}
{State6}
{State39}
{State40}
{State17}
{State41}
{State32}
{State29}
{State42}
{State14}
{State43}
{State44}
{State9}
{State45}
{State26}
{State35}
{State38}
{State21}
{State46}
{State4}
{State1}
{State47}
{State19}
{State40}
{State33}
{State28}
{State43}
{State12}
{State48}
{State49}
{State11}
{State44}
{State27}
{State34}
{State39}
{State20}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State5}
{State21}
{State22}
{State23}
{State24}
{State25}
{State26}
{State8}
{State27}
{State28}
{State15}
{State29}
{State30}
{State31}
{State32}
{State16}
{State33}
{State34}
{State7}
{State35}
{State24}
{State36}
{State37}
{State23}
{State38}
{State6}
{State39}
{State40}
{State17}
{State41}
{State32}
{State29}
{State42}
{State14}
{State43}
{State44}
{State9}
{State45}
{State26}
{State35}
{State38}
{State21}
{State46}
{State4}
{State1}
{State47}
{State19}
{State40}
{State33}
{State28}
{State43}
{State12}
{State48}
{State49}
{State11}
{State44}
{State27}
{State34}
{State39}
{State20}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State5}
{State21}
{State22}
{State23}
{State24}
{State25}
{State26}
{State8}
{State27}
{State28}
{State15}
{State29}
{State30}
{State31}
{State32}
{State16}
{State33}
{State34}
{State7}
{State35}
{State24}
{State36}
{State37}
{State23}
{State38}
{State6}
{State39}
{State40}
{State17}
{State41}
{State32}
{State29}
{State42}
{State14}
{State43}
{State44}
{State9}
{State45}
{State26}
{State35}
{State38}
{State21}
{State46}
{State4}
{State1}
{State47}
{State19}
{State40}
{State33}
{State28}
{State43}
{State12}
{State48}
{State49}
{State11}
{State44}
{State27}
{State34}
{State39}
{State20}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State5}
{State21}
{State22}
{State23}
{State24}
{State25}
{State26}
{State8}
{State27}
{State28}
{State15}
{State29}
{State30}
{State31}
{State32}
{State16}
{State33}
{State34}
{State7}
{State35}
{State24}
{State36}
{State37}
{State23}
{State38}
{State6}
{State39}
{State40}
{State17}
{State41}
{State32}
{State29}
{State42}
{State14}
{State43}
{State44}
{State9}
{State45}
{State26}
{State35}
ECONOMYSTATE_END
}
elsif($markets{$market} == 3) {	# var2
  print ECONOMYSTATE <<ECONOMYSTATE_END;
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State21}
{State2}
{State7}
{State22}
{State23}
{State24}
{State25}
{State26}
{State27}
{State10}
{State28}
{State29}
{State17}
{State30}
{State31}
{State32}
{State33}
{State18}
{State34}
{State35}
{State9}
{State36}
{State25}
{State37}
{State38}
{State24}
{State39}
{State8}
{State1}
{State40}
{State19}
{State41}
{State33}
{State30}
{State42}
{State16}
{State43}
{State44}
{State11}
{State45}
{State27}
{State36}
{State39}
{State22}
{State46}
{State6}
{State3}
{State47}
{State21}
{State40}
{State34}
{State29}
{State43}
{State14}
{State48}
{State49}
{State13}
{State44}
{State28}
{State35}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State21}
{State2}
{State7}
{State22}
{State23}
{State24}
{State25}
{State26}
{State27}
{State10}
{State28}
{State29}
{State17}
{State30}
{State31}
{State32}
{State33}
{State18}
{State34}
{State35}
{State9}
{State36}
{State25}
{State37}
{State38}
{State24}
{State39}
{State8}
{State1}
{State40}
{State19}
{State41}
{State33}
{State30}
{State42}
{State16}
{State43}
{State44}
{State11}
{State45}
{State27}
{State36}
{State39}
{State22}
{State46}
{State6}
{State3}
{State47}
{State21}
{State40}
{State34}
{State29}
{State43}
{State14}
{State48}
{State49}
{State13}
{State44}
{State28}
{State35}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State21}
{State2}
{State7}
{State22}
{State23}
{State24}
{State25}
{State26}
{State27}
{State10}
{State28}
{State29}
{State17}
{State30}
{State31}
{State32}
{State33}
{State18}
{State34}
{State35}
{State9}
{State36}
{State25}
{State37}
{State38}
{State24}
{State39}
{State8}
{State1}
{State40}
{State19}
{State41}
{State33}
{State30}
{State42}
{State16}
{State43}
{State44}
{State11}
{State45}
{State27}
{State36}
{State39}
{State22}
{State46}
{State6}
{State3}
{State47}
{State21}
{State40}
{State34}
{State29}
{State43}
{State14}
{State48}
{State49}
{State13}
{State44}
{State28}
{State35}
{State1}
{State2}
{State3}
{State4}
{State5}
{State6}
{State7}
{State8}
{State9}
{State10}
{State11}
{State12}
{State13}
{State14}
{State15}
{State16}
{State17}
{State18}
{State19}
{State20}
{State21}
{State2}
{State7}
{State22}
{State23}
{State24}
{State25}
{State26}
{State27}
{State10}
{State28}
{State29}
{State17}
{State30}
{State31}
{State32}
{State33}
{State18}
{State34}
{State35}
{State9}
{State36}
{State25}
{State37}
{State38}
{State24}
{State39}
{State8}
{State1}
{State40}
{State19}
{State41}
{State33}
{State30}
{State42}
{State16}
{State43}
{State44}
{State11}
{State45}
ECONOMYSTATE_END
}
close(ECONOMYSTATE);
print "Created economy state time-series file $economystatefile\n";

############################################################## Income tree file

open(INCOMETREE, ">$incometreefile")
  || die "Cannot create income tree file $incometreefile: $!\n";
if($markets{$market} == 1) {
  print INCOMETREE <<INCOMETREE_END;
Economy
\tEconomy
\t\tState1
LandUse
\tLandUse
\t\tGL1     GL2     GL3     AL1     AL2     AL3
INCOMETREE_END
}
elsif($markets{$market} == 2) {
  print INCOMETREE <<INCOMETREE_END;
Economy
\tEconomy
\t\tState1  State2  State3  State4  State5  State6  State7  State8 State9  State10 State11 State12 State13 State14 State15 State16 State17 State18 State19 State20 State21 State22 State23 State24 State25 State26 State27 State28 State29 State30 State31 State32 State33 State34 State35 State36 State37 State38 State39 State40 State41 State42 State43 State44 State45 State46 State47 State48 State49
LandUse
\tLandUse
\t\tGL1     GL2     GL3     AL1     AL2     AL3
INCOMETREE_END
}
elsif($markets{$market} == 3) {
  print INCOMETREE <<INCOMETREE_END;
Economy
	Economy
		State1	State2	State3	State4	State5	State6	State7	State8	State9	State10	State11	State12	State13	State14	State15	State16	State17	State18	State19	State20	State21	State22	State23	State24	State25	State26	State27	State28	State29	State30	State31	State32	State33	State34	State35	State36	State37	State38	State39	State40	State41	State42	State43	State44	State45	State46	State47	State48	State49
LandUse
	LandUse
		GL1	GL2	GL3	AL1	AL2	AL3
INCOMETREE_END
}
close(INCOMETREE);
print "Created income tree file $incometreefile\n";

############################################################## Income data file

open(INCOMEDATA, ">$incomedatafile")
  || die "Cannot create income data file $incomedatafile: $!\n";
if($markets{$market} == 1) {
  print INCOMEDATA <<INCOMEDATA_END;
Economy	LandUse
State1  GL1     5.5
State1  GL2     5.5
State1  GL3     5.5
State1  AL1     5
State1  AL2     5
State1  AL3     5
INCOMEDATA_END
}
elsif($markets{$market} == 2) {
  print INCOMEDATA <<INCOMEDATA_END;
Economy	LandUse
State1  GL1     3.875
State1  GL2     3.875
State1  GL3     3.875
State1  AL1     6.625
State1  AL2     6.625
State1  AL3     6.625
State2  GL1     3.75
State2  GL2     3.75
State2  GL3     3.75
State2  AL1     6.875
State2  AL2     6.875
State2  AL3     6.875
State3  GL1     3.875
State3  GL2     3.875
State3  GL3     3.875
State3  AL1     7
State3  AL2     7
State3  AL3     7
State4  GL1     4.25
State4  GL2     4.25
State4  GL3     4.25
State4  AL1     6.875
State4  AL2     6.875
State4  AL3     6.875
State5  GL1     4.625
State5  GL2     4.625
State5  GL3     4.625
State5  AL1     6.625
State5  AL2     6.625
State5  AL3     6.625
State6  GL1     5.25
State6  GL2     5.25
State6  GL3     5.25
State6  AL1     6.125
State6  AL2     6.125
State6  AL3     6.125
State7  GL1     5.875
State7  GL2     5.875
State7  GL3     5.875
State7  AL1     5.625
State7  AL2     5.625
State7  AL3     5.625
State8  GL1     6.25
State8  GL2     6.25
State8  GL3     6.25
State8  AL1     5
State8  AL2     5
State8  AL3     5
State9  GL1     6.625
State9  GL2     6.625
State9  GL3     6.625
State9  AL1     4.375
State9  AL2     4.375
State9  AL3     4.375
State10 GL1     6.75
State10 GL2     6.75
State10 GL3     6.75
State10 AL1     3.875
State10 AL2     3.875
State10 AL3     3.875
State11 GL1     6.625
State11 GL2     6.625
State11 GL3     6.625
State11 AL1     3.375
State11 AL2     3.375
State11 AL3     3.375
State12 GL1     6.25
State12 GL2     6.25
State12 GL3     6.25
State12 AL1     3.125
State12 AL2     3.125
State12 AL3     3.125
State13 GL1     5.875
State13 GL2     5.875
State13 GL3     5.875
State13 AL1     3
State13 AL2     3
State13 AL3     3
State14 GL1     5.25
State14 GL2     5.25
State14 GL3     5.25
State14 AL1     3.125
State14 AL2     3.125
State14 AL3     3.125
State15 GL1     4.625
State15 GL2     4.625
State15 GL3     4.625
State15 AL1     3.375
State15 AL2     3.375
State15 AL3     3.375
State16 GL1     4.25
State16 GL2     4.25
State16 GL3     4.25
State16 AL1     3.875
State16 AL2     3.875
State16 AL3     3.875
State17 GL1     3.875
State17 GL2     3.875
State17 GL3     3.875
State17 AL1     4.375
State17 AL2     4.375
State17 AL3     4.375
State18 GL1     3.75
State18 GL2     3.75
State18 GL3     3.75
State18 AL1     5
State18 AL2     5
State18 AL3     5
State19 GL1     3.875
State19 GL2     3.875
State19 GL3     3.875
State19 AL1     5.625
State19 AL2     5.625
State19 AL3     5.625
State20 GL1     4.25
State20 GL2     4.25
State20 GL3     4.25
State20 AL1     6.125
State20 AL2     6.125
State20 AL3     6.125
State21 GL1     5.25
State21 GL2     5.25
State21 GL3     5.25
State21 AL1     6.875
State21 AL2     6.875
State21 AL3     6.875
State22 GL1     5.875
State22 GL2     5.875
State22 GL3     5.875
State22 AL1     7
State22 AL2     7
State22 AL3     7
State23 GL1     6.25
State23 GL2     6.25
State23 GL3     6.25
State23 AL1     6.875
State23 AL2     6.875
State23 AL3     6.875
State24 GL1     6.625
State24 GL2     6.625
State24 GL3     6.625
State24 AL1     6.625
State24 AL2     6.625
State24 AL3     6.625
State25 GL1     6.75
State25 GL2     6.75
State25 GL3     6.75
State25 AL1     6.125
State25 AL2     6.125
State25 AL3     6.125
State26 GL1     6.625
State26 GL2     6.625
State26 GL3     6.625
State26 AL1     5.625
State26 AL2     5.625
State26 AL3     5.625
State27 GL1     5.875
State27 GL2     5.875
State27 GL3     5.875
State27 AL1     4.375
State27 AL2     4.375
State27 AL3     4.375
State28 GL1     5.25
State28 GL2     5.25
State28 GL3     5.25
State28 AL1     3.875
State28 AL2     3.875
State28 AL3     3.875
State29 GL1     4.25
State29 GL2     4.25
State29 GL3     4.25
State29 AL1     3.125
State29 AL2     3.125
State29 AL3     3.125
State30 GL1     3.875
State30 GL2     3.875
State30 GL3     3.875
State30 AL1     3
State30 AL2     3
State30 AL3     3
State31 GL1     3.75
State31 GL2     3.75
State31 GL3     3.75
State31 AL1     3.125
State31 AL2     3.125
State31 AL3     3.125
State32 GL1     3.875
State32 GL2     3.875
State32 GL3     3.875
State32 AL1     3.375
State32 AL2     3.375
State32 AL3     3.375
State33 GL1     4.625
State33 GL2     4.625
State33 GL3     4.625
State33 AL1     4.375
State33 AL2     4.375
State33 AL3     4.375
State34 GL1     5.25
State34 GL2     5.25
State34 GL3     5.25
State34 AL1     5
State34 AL2     5
State34 AL3     5
State35 GL1     6.25
State35 GL2     6.25
State35 GL3     6.25
State35 AL1     6.125
State35 AL2     6.125
State35 AL3     6.125
State36 GL1     6.75
State36 GL2     6.75
State36 GL3     6.75
State36 AL1     6.875
State36 AL2     6.875
State36 AL3     6.875
State37 GL1     6.625
State37 GL2     6.625
State37 GL3     6.625
State37 AL1     7
State37 AL2     7
State37 AL3     7
State38 GL1     5.875
State38 GL2     5.875
State38 GL3     5.875
State38 AL1     6.625
State38 AL2     6.625
State38 AL3     6.625
State39 GL1     4.625
State39 GL2     4.625
State39 GL3     4.625
State39 AL1     5.625
State39 AL2     5.625
State39 AL3     5.625
State40 GL1     4.25
State40 GL2     4.25
State40 GL3     4.25
State40 AL1     5
State40 AL2     5
State40 AL3     5
State41 GL1     3.75
State41 GL2     3.75
State41 GL3     3.75
State41 AL1     3.875
State41 AL2     3.875
State41 AL3     3.875
State42 GL1     4.625
State42 GL2     4.625
State42 GL3     4.625
State42 AL1     3
State42 AL2     3
State42 AL3     3
State43 GL1     5.875
State43 GL2     5.875
State43 GL3     5.875
State43 AL1     3.375
State43 AL2     3.375
State43 AL3     3.375
State44 GL1     6.25
State44 GL2     6.25
State44 GL3     6.25
State44 AL1     3.875
State44 AL2     3.875
State44 AL3     3.875
State45 GL1     6.75
State45 GL2     6.75
State45 GL3     6.75
State45 AL1     5
State45 AL2     5
State45 AL3     5
State46 GL1     4.625
State46 GL2     4.625
State46 GL3     4.625
State46 AL1     7
State46 AL2     7
State46 AL3     7
State47 GL1     3.75
State47 GL2     3.75
State47 GL3     3.75
State47 AL1     6.125
State47 AL2     6.125
State47 AL3     6.125
State48 GL1     6.625
State48 GL2     6.625
State48 GL3     6.625
State48 AL1     3
State48 AL2     3
State48 AL3     3
State49 GL1     6.75
State49 GL2     6.75
State49 GL3     6.75
State49 AL1     3.125
State49 AL2     3.125
State49 AL3     3.125
INCOMEDATA_END
}
elsif($markets{$market} == 3) {
  print INCOMEDATA <<INCOMEDATA_END;
Economy	LandUse
State1	GL1	6.125
State1	GL2	6.125
State1	GL3	6.125
State1	AL1	5.5
State1	AL2	5.5
State1	AL3	5.5
State2	GL1	6.5
State2	GL2	6.5
State2	GL3	6.5
State2	AL1	6
State2	AL2	6
State2	AL3	6
State3	GL1	6.875
State3	GL2	6.875
State3	GL3	6.875
State3	AL1	6.375
State3	AL2	6.375
State3	AL3	6.375
State4	GL1	7
State4	GL2	7
State4	GL3	7
State4	AL1	6.625
State4	AL2	6.625
State4	AL3	6.625
State5	GL1	6.875
State5	GL2	6.875
State5	GL3	6.875
State5	AL1	6.75
State5	AL2	6.75
State5	AL3	6.75
State6	GL1	6.5
State6	GL2	6.5
State6	GL3	6.5
State6	AL1	6.625
State6	AL2	6.625
State6	AL3	6.625
State7	GL1	6.125
State7	GL2	6.125
State7	GL3	6.125
State7	AL1	6.375
State7	AL2	6.375
State7	AL3	6.375
State8	GL1	5.5
State8	GL2	5.5
State8	GL3	5.5
State8	AL1	6
State8	AL2	6
State8	AL3	6
State9	GL1	4.875
State9	GL2	4.875
State9	GL3	4.875
State9	AL1	5.5
State9	AL2	5.5
State9	AL3	5.5
State10	GL1	4.5
State10	GL2	4.5
State10	GL3	4.5
State10	AL1	5
State10	AL2	5
State10	AL3	5
State11	GL1	4.125
State11	GL2	4.125
State11	GL3	4.125
State11	AL1	4.5
State11	AL2	4.5
State11	AL3	4.5
State12	GL1	4
State12	GL2	4
State12	GL3	4
State12	AL1	4
State12	AL2	4
State12	AL3	4
State13	GL1	4.125
State13	GL2	4.125
State13	GL3	4.125
State13	AL1	3.625
State13	AL2	3.625
State13	AL3	3.625
State14	GL1	4.5
State14	GL2	4.5
State14	GL3	4.5
State14	AL1	3.375
State14	AL2	3.375
State14	AL3	3.375
State15	GL1	4.875
State15	GL2	4.875
State15	GL3	4.875
State15	AL1	3.25
State15	AL2	3.25
State15	AL3	3.25
State16	GL1	5.5
State16	GL2	5.5
State16	GL3	5.5
State16	AL1	3.375
State16	AL2	3.375
State16	AL3	3.375
State17	GL1	6.125
State17	GL2	6.125
State17	GL3	6.125
State17	AL1	3.625
State17	AL2	3.625
State17	AL3	3.625
State18	GL1	6.5
State18	GL2	6.5
State18	GL3	6.5
State18	AL1	4
State18	AL2	4
State18	AL3	4
State19	GL1	6.875
State19	GL2	6.875
State19	GL3	6.875
State19	AL1	4.5
State19	AL2	4.5
State19	AL3	4.5
State20	GL1	7
State20	GL2	7
State20	GL3	7
State20	AL1	5
State20	AL2	5
State20	AL3	5
State21	GL1	6.875
State21	GL2	6.875
State21	GL3	6.875
State21	AL1	5.5
State21	AL2	5.5
State21	AL3	5.5
State22	GL1	5.5
State22	GL2	5.5
State22	GL3	5.5
State22	AL1	6.625
State22	AL2	6.625
State22	AL3	6.625
State23	GL1	4.875
State23	GL2	4.875
State23	GL3	4.875
State23	AL1	6.75
State23	AL2	6.75
State23	AL3	6.75
State24	GL1	4.5
State24	GL2	4.5
State24	GL3	4.5
State24	AL1	6.625
State24	AL2	6.625
State24	AL3	6.625
State25	GL1	4.125
State25	GL2	4.125
State25	GL3	4.125
State25	AL1	6.375
State25	AL2	6.375
State25	AL3	6.375
State26	GL1	4
State26	GL2	4
State26	GL3	4
State26	AL1	6
State26	AL2	6
State26	AL3	6
State27	GL1	4.125
State27	GL2	4.125
State27	GL3	4.125
State27	AL1	5.5
State27	AL2	5.5
State27	AL3	5.5
State28	GL1	4.875
State28	GL2	4.875
State28	GL3	4.875
State28	AL1	4.5
State28	AL2	4.5
State28	AL3	4.5
State29	GL1	5.5
State29	GL2	5.5
State29	GL3	5.5
State29	AL1	4
State29	AL2	4
State29	AL3	4
State30	GL1	6.5
State30	GL2	6.5
State30	GL3	6.5
State30	AL1	3.375
State30	AL2	3.375
State30	AL3	3.375
State31	GL1	6.875
State31	GL2	6.875
State31	GL3	6.875
State31	AL1	3.25
State31	AL2	3.25
State31	AL3	3.25
State32	GL1	7
State32	GL2	7
State32	GL3	7
State32	AL1	3.375
State32	AL2	3.375
State32	AL3	3.375
State33	GL1	6.875
State33	GL2	6.875
State33	GL3	6.875
State33	AL1	3.625
State33	AL2	3.625
State33	AL3	3.625
State34	GL1	6.125
State34	GL2	6.125
State34	GL3	6.125
State34	AL1	4.5
State34	AL2	4.5
State34	AL3	4.5
State35	GL1	5.5
State35	GL2	5.5
State35	GL3	5.5
State35	AL1	5
State35	AL2	5
State35	AL3	5
State36	GL1	4.5
State36	GL2	4.5
State36	GL3	4.5
State36	AL1	6
State36	AL2	6
State36	AL3	6
State37	GL1	4
State37	GL2	4
State37	GL3	4
State37	AL1	6.625
State37	AL2	6.625
State37	AL3	6.625
State38	GL1	4.125
State38	GL2	4.125
State38	GL3	4.125
State38	AL1	6.75
State38	AL2	6.75
State38	AL3	6.75
State39	GL1	4.875
State39	GL2	4.875
State39	GL3	4.875
State39	AL1	6.375
State39	AL2	6.375
State39	AL3	6.375
State40	GL1	6.5
State40	GL2	6.5
State40	GL3	6.5
State40	AL1	5
State40	AL2	5
State40	AL3	5
State41	GL1	7
State41	GL2	7
State41	GL3	7
State41	AL1	4
State41	AL2	4
State41	AL3	4
State42	GL1	6.125
State42	GL2	6.125
State42	GL3	6.125
State42	AL1	3.25
State42	AL2	3.25
State42	AL3	3.25
State43	GL1	4.875
State43	GL2	4.875
State43	GL3	4.875
State43	AL1	3.625
State43	AL2	3.625
State43	AL3	3.625
State44	GL1	4.5
State44	GL2	4.5
State44	GL3	4.5
State44	AL1	4
State44	AL2	4
State44	AL3	4
State45	GL1	4
State45	GL2	4
State45	GL3	4
State45	AL1	5
State45	AL2	5
State45	AL3	5
State46	GL1	6.125
State46	GL2	6.125
State46	GL3	6.125
State46	AL1	6.75
State46	AL2	6.75
State46	AL3	6.75
State47	GL1	7
State47	GL2	7
State47	GL3	7
State47	AL1	6
State47	AL2	6
State47	AL3	6
State48	GL1	4.125
State48	GL2	4.125
State48	GL3	4.125
State48	AL1	3.25
State48	AL2	3.25
State48	AL3	3.25
State49	GL1	4
State49	GL2	4
State49	GL3	4
State49	AL1	3.375
State49	AL2	3.375
State49	AL3	3.375
INCOMEDATA_END
}
close(INCOMEDATA);
print "Created income data file $incomedatafile\n";

############################################################### Yield tree file

open(YIELDTREE, ">$yieldtreefile")
  || die "Cannot create yield tree file $yieldtreefile: $!\n";
print YIELDTREE <<YIELDTREE_END;
Climate
	NoClimate
		NoClimate
Biophysical
	NoBiophys
		NoBiophys
LandUse
	LandUse
		GL1	GL2	GL3	AL1	AL2	AL3
YIELDTREE_END
close(YIELDTREE);
print "Created yield tree file $yieldtreefile\n";

############################################################### Yield data file

open(YIELDDATA, ">$yielddatafile")
  || die "Cannot create yield data file $yielddatafile: $!\n";
print YIELDDATA <<YIELDDATA_END;
NoClimate	NoBiophys	LandUse
NoClimate	NoBiophys	GL1	4.0
NoClimate	NoBiophys	GL2	5.0
NoClimate	NoBiophys	GL3	6.0
NoClimate	NoBiophys	AL1	4.5
NoClimate	NoBiophys	AL2	5.5
NoClimate	NoBiophys	AL3	6.5
YIELDDATA_END
close(YIELDDATA);
print "Created yield data file $yielddatafile\n";

##################################################################### Grid file

open(GRID, ">$gridfile") || die "Cannot create grid file $gridfile: $!\n";
print GRID <<GRID_END;
ncols $xsize
nrows $ysize
xllcorner 0.570000
yllcorner 850.400000
cellsize 1.000000
FEARLUS-LandUseID Initial
GRID_END

for(my $y = 0; $y < $ysize; $y++) {
  for(my $x = 0; $x < $xsize; $x++) {
    my $i = $coordpatch{$x, $y};

    print GRID $patchlu{$i}." ";
  }
  print GRID "\n";
}

close(GRID);
print "Created grid file $gridfile\n";

##################################################### Report configuration file

my $reportgridfile = $reportfile;
$reportgridfile =~ s/\.txt$/.grd/;
open(REPCFG, ">$repcfgfile")
  || die "Cannot create FEARLUS report configuration file $repcfgfile: $!\n";
print REPCFG <<REPCFG_END;
DefaultYearsToReport: Every 1
LandUseGridFileReport Options: GridFile=$reportgridfile
ParcelSubPopReport
WealthGridFileReport Options: GridFile=$reportgridfile
LandManagerGridFileReport Options: GridFile=$reportgridfile
SubPopDeathReport
ManagerIncomeReport
GovernmentExpenditureReport
End
REPCFG_END
close(REPCFG);
print "Created FEARLUS report configuration file $repcfgfile\n";

############################################################### Government file

open(GOVT, ">$govtfile")
  || die "Cannot create government file $govtfile: $!\n";

foreach my $param (@govtparam) {
  if($param =~ /^LandUse/) {
    if($param eq 'LandUse:Target') {
      while(my($lu, $target) = each(%landuse_target)) {
	next if $target eq 'no';
	print GOVT "LandUse: $lu $target\n";
      }
    }
    else {
      while(my($lu, $reward) = each(%landuse_reward)) {
	next if $reward eq 'no';
	if($param eq 'LandUse:Reward') {
	  print GOVT "LandUse: $lu $reward\n";
	}
	elsif($param eq 'LandUse') {
	  print GOVT "LandUse: $lu\n";
	}
	else {
	  die "Invalid government parameter: $param\n";
	}
      }
    }
  }
  elsif($param =~ /^Species/) {
    if($param eq 'Species:Target') {
      while(my($spp, $target) = each(%species_target)) {
	next if $target eq 'no';
	print GOVT "Species: $spp $target\n";
      }
    }
    else {
      while(my($spp, $reward) = each(%species_reward)) {
	next if $reward eq 'no';
	if($param eq 'Species:Reward') {
	  print GOVT "Species: $spp $reward\n";
	}
	elsif($param eq 'Species') {
	  print GOVT "Species: $spp\n";
	}
	else {
	  die "Invalid government parameter: $param\n";
	}
      }
    }
  }
  elsif(defined($allgovparams{$param})) {
    my @values = @{$allgovparams{$param}};
    foreach my $value (@values) {
      print GOVT "$param: $value\n";
    }
  }
  else {
    die "Invalid government parameter: $param\n";
  }
}
close(GOVT);
print "Created government file $govtfile\n";

print "You should run the command:\n\$FEARLUSSPOMHOME/fearlus-1.1.4_spom-2.3 "
  ."-b -p $modelfile -R $repcfgfile -r $reportfile -s\n...from subdirectory: "
  ."$dir\n";

exit 0;

###############################################################################

# compute a similarity score for a land use and its neighbours--10 points for
# each N, S, E or W the same, 1 point for each NE, SE, SW, NW the same.

sub similar {
  my ($lu, $x, $y, $xsize, $ysize, $plu, $cp) = @_;

  my $score = 0;

  # Manage toroids

  my $xp1 = ($x == $xsize - 1 ? 0 : $x + 1);
  my $xm1 = ($x == 0 ? $xsize - 1 : $x - 1);
  my $yp1 = ($y == $ysize - 1 ? 0 : $y + 1);
  my $ym1 = ($y == 0 ? $ysize - 1 : $y - 1);

  # Initialise directions

  my @nsewx = ($xm1, 0, $xp1, 0);
  my @nsewy = (0, $ym1, 0, $yp1);
  my @neseswnwx = ($xm1, $xm1, $xp1, $xp1);
  my @neseswnwy = ($ym1, $yp1, $ym1, $yp1);

  # Compute score

  for(my $i = 0; $i < 4; $i++) {
    my $nsewi = $$cp{$nsewx[$i], $nsewy[$i]};
    my $neseswnwi = $$cp{$neseswnwx[$i], $neseswnwy[$i]};

    $score += 10 if($$plu{$nsewi} == $lu);
    $score++ if($$plu{$neseswnwi} == $lu);
  }

  return $score;
}
