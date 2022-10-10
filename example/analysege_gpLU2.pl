#!/usr/bin/perl
#
# analyse.pl
#
# Analysis script to analyse results from SSS runs. The output is a CSV format
# summary of the results from each run, listing the parameters first, then
# the results: the number of bankruptcies, the amount of land use change,
# the year of extinction of each species, and the abundance of each species.
#
# Number of species at a given time step
# Level of occupancy at each time step
# Shannon index and evenness measure

use strict;

my $report_start = 100;
my $report_stop = 299;
my $small_amount = 0.0001;
my $expected_nspp = 10;
my $expected_nlu = 6;

print "Report start year,$report_start,Report stop year,$report_stop,"
  ."(inclusive)\n";
  
#ARGV[0]==1 corresponds to the SSS-20080511 directory,
#which means there is no $rat variable.
if($ARGV[0] == 1) {
  print "Government,Sink,Market,BET,ASP,Reward,Run,Expenditure,Bankruptcies,"
  ."Land.Use.Change";
}
elsif($ARGV[0] == 6 || $ARGV[0] == 7) {
  print "Government,Sink,StopC2,Market,BET,ASP,Reward,Ratio,Run,Expenditure,"
    ."Bankruptcies,Land.Use.Change";
}
elsif($ARGV[0] == 8 || $ARGV[0] == 9) {
  print "Government,Sink,StopC2,Market,BET,ASP,Reward,Ratio,Run,Expenditure,"
    ."Income,Subsidy,Subsidy.Proportion,Bankruptcies,Land.Use.Change";
}
else {
  print "Government,Sink,Market,BET,ASP,Reward,Ratio,Run,Expenditure,"
    ."Bankruptcies,Land.Use.Change";
}

for(my $i = 1; $i <= $expected_nlu; $i++) {
  print ",Occupancy.LU.$i";
}
for(my $i = 1; $i <= $expected_nspp; $i++) {
  print ",Extinction.SPP.$i";
}
for(my $i = 1; $i <= $expected_nspp; $i++) {
  print ",Occupancy.SPP.$i";
}
print ",Shannon,Equitability,Richness\n";

my @govern;
my @reward;
my @ratio;
my $pdir;
my $stopC2;
my @sink;
my @asp;
              
if($ARGV[0] == 1) {
  @govern = ("SubsetActivity", "SubsetSpecies");
  @reward = ("0.0", "5.0", "10.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 0;
  $pdir = "SSS-20080511";
}
elsif($ARGV[0] == 2) {
  @govern = ("RewardActivity", "RewardSpecies");
  @reward = ("0.0", "5.0", "10.0");
  @ratio=("2.0", "3.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 0;
  $pdir = "SSSii-20080424";
}
elsif($ARGV[0] == 3) {
  @govern = ("BudgetRewardActivity", "BudgetRewardSpecies");
  @reward = ("1.0-0.0", "1.0-5000.0", "1.0-10000.0", 
	     "1.0-15000.0", "1.0-20000.0");
  @ratio=("1.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 0;
  $pdir = "SSSii-B-20080424";
}
elsif($ARGV[0] == 4) {
  @govern = ("RewardActivity","RewardSpecies");
  @reward = ("0.0", "5.0", "10.0");
  @ratio=("1.0","2.0","3.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 1;
  $pdir = "SSSiii-20080424";
}
elsif($ARGV[0] == 5) {
  @govern = ("BudgetRewardActivity","BudgetRewardSpecies");
  @reward = ("1.0-0.0", "1.0-5000.0", "1.0-10000.0",
	     "1.0-15000.0", "1.0-20000.0");
  @ratio=("1.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 1;
  $pdir = "SSSiii-B-20080424";
}
elsif($ARGV[0] == 6) {
  @govern = ("ClusterActivity", "ClusterSpecies");
  @reward = ("0.0", "5.0", "10.0");
  @ratio = ("1.0", "2.0", "3.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 0;
  $pdir = "SSSii";
}
elsif($ARGV[0] == 7) {
  @govern = ("ClusterActivity", "ClusterSpecies");
  @reward = ("0.0", "5.0", "10.0");
  @ratio = ("1.0", "2.0", "3.0");
  @sink = {"sink", "nosink"};
  @asp = {"0.5", "1.0", "5.0"};
  $stopC2 = 1;
  $pdir = "SSSiii";
}
elsif($ARGV[0] == 8) {
  @govern = ("ClusterActivity", "ClusterSpecies", "RewardActivity",
	     "RewardSpecies");
  @reward = ("1.0", "2.0", "3.0", "4.0", "5.0", "6.0", "7.0", "8.0", "9.0",
	     "10.0");
  @ratio = ("1.0", "2.0", "10.0");
  @sink = ("nosink");
  @asp = ("1.0", "5.0");
  $stopC2 = 1;
  $pdir = "Cluster2";
  $report_stop = 199;
}
elsif($ARGV[0] == 9) {
  @govern = ("RewardActivity", "RewardSpecies");
  @reward = ("15.0", "20.0", "25.0", "30.0", "40.0", "50.0", "100.0");
  @ratio = ("1.0");
  @sink = ("nosink");
  @asp = ("1.0", "5.0");
  $stopC2 = 1;
  $pdir = "Cluster2-2";
  $report_stop = 199;
}
else {
  print "Error: unexpected argument on command line.\n";
}

# First set of experiments (used for the Sources, Sinks and Sustainability
# book chapter, and related talks)

#1 corresponds to the SSS-20080511 directory.
#2 corresponds to the SSSii-20080424 directory.
#3 corresponds to the SSSii-B-20080424 directory.
#4 corresponds to the SSSiii-20080424 directory.
#5 corresponds to the SSSiii-B-20080424 directory.

# Second set of experiments (used for US-IALE 2009)

#6 corresponds to the SSSii directory
#7 corresponds to the SSSiii directory

# Third set of experiments

#8 corresponds to the Cluster2 directory

foreach my $govt (@govern) {
  foreach my $sink (@sink) {
    my $psink = $sink eq 'sink' ? 1 : 0;
    foreach my $market ('var2', 'flat') {
      foreach my $bet ('25.0', '30.0') {
	foreach my $asp (@asp) {
	  foreach my $rwd (@reward) {
            if($ARGV[0] == 1) {
	      my $dir = "SSS_dir_${sink}_${govt}_all_${rwd}_${market}_"
                  ."${bet}_noapproval_0_${asp}_";

	      for(my $run = 1; $run <= 20; $run++) {
	        my $strun = sprintf("%03d", $run);

#      	        my $grid = "SSS_grid__________${strun}.grd";
	        my $report = "SSS_report_${sink}_${govt}_all_${rwd}_"
                  ."${market}_${bet}_noapproval_0_${asp}_${strun}.txt";
	        my $grid = "SSS_report_${sink}_${govt}_all_${rwd}_"
                  ."${market}_${bet}_noapproval_0_${asp}_${strun}.grd";
	        my $extinct = "SSS_spomresult_${sink}_${govt}_all_"
		  ."${rwd}_${market}_${bet}_noapproval_0_${asp}_"
                  ."${strun}-extinct.csv";
	        my $occup = "SSS_spomresult_${sink}_${govt}_all_${rwd}_"
		  ."${market}_${bet}_noapproval_0_${asp}_${strun}-lspp.csv";

	        my ($income, $reward, $preward,
	    	    $expenditure, $bankrupt, $luc, $extinct, $occupancy,
		    $shannon, $equitability, $richness)
		= &analyse_files("$pdir/$dir/$grid",
				 "$pdir/$dir/$report",
				 "$pdir/$dir/$extinct",
				 "$pdir/$dir/$occup");

	        print "$govt,$psink,$market,$bet,$asp,$rwd,$run,$expenditure,";
	        print join(",", @{$bankrupt}), ",";
	        print join(",", @{$luc}), ",";
	        print join(",", @{$extinct}), ",";
	        print join(",", @{$occupancy}), ",$shannon,"
		  ."$equitability,$richness\n";
              }
            }
            else {
	      foreach my $rat (@ratio) {
	        my $dir = "SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_"
                  ."${market}_${bet}_noapproval_0_${asp}_";

	        for(my $run = 1; $run <= 20; $run++) {
	          my $strun = sprintf("%03d", $run);

#      	          my $grid = "SSS_grid__________${strun}.grd";
	          my $report = "SSS_report_${sink}_${govt}_all_${rwd}_"
                    ."${rat}_${market}_${bet}_noapproval_0_${asp}_"
                    ."${strun}.txt";
	          my $grid = "SSS_report_${sink}_${govt}_all_${rwd}_"
                    ."${rat}_${market}_${bet}_noapproval_0_${asp}_"
                    ."${strun}.grd";
	          my $extinct = "SSS_spomresult_${sink}_${govt}_all_"
		    ."${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
                    ."${strun}-extinct.csv";
	          my $occup = "SSS_spomresult_${sink}_${govt}_all_"
		    ."${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
		    ."${strun}-lspp.csv";

	          my ($income, $reward, $preward,
	    	      $expenditure, $bankrupt, $luc, $extinct, $occupancy,
		      $shannon, $equitability, $richness)
		  = &analyse_files("$pdir/$dir/$grid",
				   "$pdir/$dir/$report",
				   "$pdir/$dir/$extinct",
				   "$pdir/$dir/$occup");

		  if($ARGV[0] == 6 || $ARGV[0] == 7) {
		    print "$govt,$psink,$stopC2,$market,$bet,$asp,$rwd,$rat,",
		      "$run,$expenditure,";
		  }
		  elsif($ARGV[0] == 8 || $ARGV[0] == 9) {
		    print "$govt,$psink,$stopC2,$market,$bet,$asp,$rwd,$rat,",
		      "$run,$expenditure,$income,$reward,$preward,";
		  }
		  else {
		    print "$govt,$psink,$market,$bet,$asp,$rwd,$rat,$run,",
		      "$expenditure,";
		  }
	          print join(",", @{$bankrupt}), ",";
	          print join(",", @{$luc}), ",";
	          print join(",", @{$extinct}), ",";
	          print join(",", @{$occupancy}), ",$shannon,"
		    ."$equitability,$richness\n";
                }
              }
            }
	  }
        }
      }
    }
  }
}


exit 0;

# analyse_files
#
# Take a list of grid, report, extinction and occupancy files as input, and
# produce an array of references to arrays of results covering bankruptcy,
# land use change, extinction, occupancy, shannon index and evenness.

sub analyse_files {
  my($grid_file, $report_file, $extinction_file, $occupancy_file) = @_;
  my @bankrupt;
  my @land_use_change;
  my @extinction;
  my @occupancy;
  my $shannon;			# This is the same as $diversity in
				# BES2007-analysis2.pl
  my $equitability;
  my $richness;

  my ($nrows, $ncols, %land_use_data)
    = &read_grid($grid_file, 'FEARLUS-LandUseID');

  my ($dummy_nrows, $dummy_ncols, %land_manager_data)
    = &read_grid($grid_file, 'FEARLUS-LandManagerID');

  @land_use_change = &get_land_use_change($report_start, $report_stop,
					  $nrows, $ncols, \%land_use_data);

  my %bankruptcy_data = &read_report($report_file, 'SubPopDeathReport');

  @bankrupt = &get_bankruptcies($report_start, $report_stop, $nrows, $ncols,
				\%land_manager_data, \%bankruptcy_data);

  my %expenditure_data = &read_report($report_file,
				      'GovernmentExpenditureReport');

  my $expenditure = &get_expenditure($report_start, $report_stop, $nrows,
				     $ncols, \%expenditure_data);

  my %income_data = &read_report($report_file, 'ManagerIncomeReport');

  my ($income, $reward, $preward) = &get_income($report_start, $report_stop,
						$nrows, $ncols,
						\%income_data);

  my ($nspp, %occupancy_data) = &read_lspp($occupancy_file);

  my %extinctions = &read_extinction($extinction_file);

  @extinction = &get_extinction($nspp, \%extinctions);

  ($shannon, $equitability, $richness, @occupancy)
    = &get_occupancy($report_start, $report_stop, $nrows * $ncols,
		     $nspp, \%occupancy_data);

  return($income, $reward, $preward,
	 $expenditure, \@bankrupt, \@land_use_change, \@extinction,
	 \@occupancy, $shannon, $equitability, $richness);
}

# get_land_use_change
#
# Return the mean land use change from report start to report stop

sub get_land_use_change {
  my ($start, $stop, $ymax, $xmax, $data) = @_;

  my $total_change = 0.0;
  my $n_change = 0;
  my @luarray;			# Assume LU IDs are ints in grd files

  for(my $i = 0; $i < $expected_nlu; $i++) {
    $luarray[$i] = 0;
  }
  
  my $nyear = 0;
  for(my $year = $start + 1; $year <= $stop; $year++) {
    next if (!defined($data->{$year - 1}) || !defined($data->{$year}));

    my $this_change = 0;
    for(my $x = 0; $x < $xmax; $x++) {
      for(my $y = 0; $y < $ymax; $y++) {
	$luarray[$data->{$year}->[$x][$y] - 1]++;

	if($data->{$year}->[$x][$y] != $data->{$year - 1}->[$x][$y]) {
	  $this_change++;
	}
      }
    }
    $total_change += $this_change / ($xmax * $ymax);
    $n_change++;
    $nyear++;
  }

  for(my $i = 0; $i <= $#luarray; $i++) {
    $luarray[$i] /= $nyear;
  }

  return ($total_change / $n_change, @luarray);
}

# get_bankruptcies
#
# Return the mean number of bankruptcies as a proportion of the land manager
# population

sub get_bankruptcies {
  my ($start, $stop, $ymax, $xmax, $mdata, $bdata) = @_;

  my $total_bankruptcies = 0.0;
  my $n_years = 0;

  for(my $year = $start; $year <= $stop; $year++) {
    next if (!defined($mdata->{$year}) || !defined($bdata->{$year}));
    my %lmgrs;
    
    for(my $x = 0; $x < $xmax; $x++) {
      for(my $y = 0; $y < $ymax; $y++) {
	if(!defined($lmgrs{$mdata->{$year}->[$x][$y]})) {
	  $lmgrs{$mdata->{$year}->[$x][$y]} = 1;
	}
      }
    }

    my $nmgrs = scalar(keys(%lmgrs));

    my $nbrupt = 0;
    my @bankruptcies = @{$bdata->{$year}};

    for(my $i = 0; $i <= $#bankruptcies; $i++) {
      my @report = @{$bankruptcies[$i]};

      if(scalar(@report) != 4) {
	die "Unexpected SubPopDeathReport line:\n".join("\t", @report)."\n";
      }

      if($report[0] eq 'Sub-population ID:'
	 && $report[2] eq 'Number of deaths:') {
	$nbrupt += $report[3];
      }
      else {
	die "Unexpected SubPopDeathReport line:\n".join("\t", @report)."\n";
      }
    }

    $total_bankruptcies += $nbrupt / $nmgrs;
    $n_years++;
  }

  return ($total_bankruptcies / $n_years);
}

# get_expenditure
#
# Return the total expenditure. The nrows and ncols variables are not used,
# but I've passed them in in case at some point we want to divide by the
# number of cells (though strictly we should also divide by the area, meaning
# that the number of cells isn't right).

sub get_expenditure {
  my ($start, $stop, $ymax, $xmax, $data) = @_;

  my $total_expenditure = 0.0;

  for(my $year = $start; $year <= $stop; $year++) {
    if(!defined($data->{$year})) {
      warn "Cannot find GovernmentExpenditureReport data for year $year\n";
      return "MissingData";
    }

    my @lines = @{$data->{$year}};

    if(scalar(@lines) != 1) {
      die "Unexpected format for GovernmentExpenditureReport, year $year:"
	."too many lines (", scalar(@lines), "\n";
    }
    my @report = @{$lines[0]};
    if(scalar(@report) != 2) {
      die "Unexpected format for GovernmentExpenditureReport, year $year:"
	."cannot read line (", join("\t", @report), ")\n";
    }

    if($report[0] eq 'Government expenditure:') {
      $total_expenditure += $report[1];
    }
    else {
      die "Unexpected format for GovernmentExpendutureReport, year $year:"
	."cannot find \"Government expenditure:\" in line (",
	  join("\t", @report), ")\n";
    }
  }
  
  return $total_expenditure;
}
    
# get_income
#
# Compute the mean income, mean reward and mean proportion reward is of income
# As for expenditure $nrows and $ncols are passed in in case they might be
# used in future, but they aren't just now.

sub get_income {
  my ($start, $stop, $ymax, $xmax, $data) = @_;
 
  my $n = 0;
  my $total_income = 0;
  my $total_reward = 0;
  my $total_preward = 0;


  for(my $year = $start; $year <= $stop; $year++) {
    if(!defined($data->{$year})) {
      warn "Cannot find ManagerIncomeReport data for year $year\n";
      return ("MissingData", "MissingData", "MissingData");
    }

    my @lines = @{$data->{$year}};

    for(my $i = 0; $i <= $#lines; $i++) {
      my @report = @{$lines[$i]};

      if(scalar(@report) != 6) {
        die "Unexpected format for ManagerIncomeReport, year $year:"
	  ."cannot read line (", join("\t", @report), ")\n";
      }

      my $income;
      my $reward;
      if($report[0] eq 'Land manager:' && $report[2] eq 'Income:'
	 && $report[4] eq 'Reward:') {
        $income = $report[3];
	$reward = $report[5];
      }
      else {
        die "Unexpected format for ManagerIncomeReport, year $year:"
	  ."cannot find \"Land manager:\", \"Income:\" and \"Reward:\" in "
	    ."line (", join("\t", @report), ")\n";
      }
      $n++;
      $total_income += $income;
      $total_reward += $reward;
      $total_preward += $reward / $income if $income > 0;
    }
  }
 
  $total_income /= $n;
  $total_reward /= $n;
  $total_preward /= $n;

  return ($total_income, $total_reward, $total_preward);
}

# get_extinction
#
# Return the year of extinction of a species, for each species, or the word
# no if it isn't extinct

sub get_extinction {
  my ($nspp, $data) = @_;

  my @results;
  for(my $i = 1; $i <= $nspp; $i++) {
    if(defined($data->{$i})) {
      push(@results, $data->{$i});
    }
    else {
      push(@results, 'NA');
    }
  }

  return @results;
}

# get_occupancy
#
# Return occupancy, shannon, richness and equitability results

sub get_occupancy {
  my ($start, $stop, $ncells, $nspp, $data) = @_;

  my $shannon = 0;
  my $richness = 0;
  my $equitability = 0;

  my @total_occupancy;
  for(my $i = 1; $i <= $nspp; $i++) {
    $total_occupancy[$i - 1] = 0;
  }

  my $n_years = 0;

  for(my $year = $start; $year <= $stop; $year++) {
    next if !defined($data->{$year});

    $n_years++;
    my %spp_occup = %{$data->{$year}};

    my @this_occup;
    my $max_occup = 0;

    $richness = 0;
    $shannon = 0.0;
    for(my $i = 1; $i <= $nspp; $i++) {
      if(defined($spp_occup{$i})) {
	$max_occup = $spp_occup{$i} > $max_occup ? $spp_occup{$i} : $max_occup;
	$richness++;
	my $prop = $spp_occup{$i} / ($ncells * $nspp);
	$shannon += $prop * log($prop);
	$this_occup[$i - 1] = $prop * $nspp;
      }
    }
    $shannon *= -1.0;

    $equitability = 0.0;
    for(my $i = 1; $i <= $nspp; $i++) {
      if(defined($spp_occup{$i})) {
	$equitability += $max_occup / $spp_occup{$i};
      }
      else {
	$equitability += $max_occup / $small_amount;
      }
      $total_occupancy[$i - 1] += $this_occup[$i - 1];
    }
    if($equitability > 0) {
      $equitability = $nspp / $equitability;
    }
  }

  if($n_years > 0) {
    for(my $i = 0; $i <= $#total_occupancy; $i++) {
      $total_occupancy[$i] /= $n_years;
    }
  }

  return ($shannon, $equitability, $richness, @total_occupancy);
}

# read_grid
#
# Read a grid file and return an associative array linking a year to the
# requested layer that year

sub read_grid {
  my($grid_file, $layer) = @_;

  my %header;
  my %years;

  open(GRID, "<$grid_file") or die "Cannot open grid file $grid_file: $!\n";

  my $header_done = 0;
  my $line_no = 0;
  while(my $line = <GRID>) {
    chomp $line;
    $line_no++;
    my @words = split(/\s/, $line);

    if($words[0] =~ /^ncols$/i
       || $words[0] =~ /^nrows$/i
       || $words[0] =~ /^xllcorner$/i || $words[0] =~ /^xllcenter$/i
       || $words[0] =~ /^yllcorner$/i || $words[0] =~ /^yllcenter$/i
       || $words[0] =~ /^cellsize$/i
       || $words[0] =~ /^nodata_value$/i) {
      if($header_done) {
	die "Invalid format in grid file $grid_file, line $line_no: Header "
	  ."data found where layer data expected\n";
      }
      $words[0] =~ tr/[A-Z]/[a-z]/;
      $header{$words[0]} = $words[1];
    }
    else {
      if(!defined($header{'ncols'})
	 || !defined($header{'nrows'})) {
	die "Invalid format in grid file $grid_file, line $line_no: Non-header"
	  ."data found where header data expected\n";
      }
      $header_done = 1;

      if($words[0] eq $layer) {
	my $year = $words[1] eq 'Year' ? $words[2] : $words[1];
	
	my @data;
	for(my $y = 0; $y < $header{'nrows'}; $y++) {
	  if(!($line = <GRID>)) {
	    die "Unexpected end of file in grid file $grid_file after line "
	      ."$line_no: expecting layer data after layer $layer\n";
	  }
	  chomp $line;
	  $line_no++;

	  @words = split(/\s/, $line);

	  if(scalar(@words) != $header{'ncols'}) {
	    die "Invalid format in grid file $grid_file, line $line_no: "
	      ."expecting $header{'ncols'} columns of layer data\n";;
	  }

	  for(my $x = 0; $x < $header{'ncols'}; $x++) {
	    $data[$x][$y] = $words[$x];
	  }
	}

	$years{$year} = \@data;
      }
      elsif(defined($words[0])) {
				# Allow for blank lines at eof
	for(my $y = 0; $y < $header{'nrows'}; $y++) {
	  if(!($line = <GRID>)) {
	    die "Unexpected end of file in grid file $grid_file after line "
	      ."$line_no: expecting layer data after layer $words[0]\n";
	  }
	  $line_no++;
	}
      }
    }
  }

  return ($header{'nrows'}, $header{'ncols'}, %years);
}

# read_extinction
#
# Read the extinction report CSV file. Return an associative array of 
# species ID to extinction year

sub read_extinction {
  my ($extinction_file) = @_;

  open(EXTINCT, "<$extinction_file") or die "Cannot open extinction file "
    ."$extinction_file: $!\n";

  my $line;
  my $line_no = 0;

  if(!($line = <EXTINCT>)) {
    die "Unexpected end of file in extinction file $extinction_file, line "
      ."$line_no\n";
  }
				# ignore the first line
  $line_no++;

  my %extinctions;

  while($line = <EXTINCT>) {
    chomp $line;
    $line_no++;

    my @cells = split(/,/, $line);

    if(scalar(@cells) < 2) {
      die "Unexpected format of extinction file $extinction_file, line "
	."$line_no: not enough columns\n";
    }
    elsif(scalar(@cells) > 2) {
      warn "Ignoring data in columns 3 onwards in extinction file "
	."$extinction_file, line $line_no\n";
    }

    $extinctions{$cells[0]} = $cells[1];
  }

  return %extinctions;
}

# read_report
#
# Read a report file, extracting the requested report in each year it appears,
# returning an associative array linking years to an array of lines, where each
# line is an array of cells (separated by tab) of the data in the requested
# report

sub read_report {
  my ($report_file, $report) = @_;

  my %years;

  open(REPORT, "<$report_file") or die "Cannot open report file $report_file: "
    ."$!\n";

  my $line_no = 0;

  while(my $line = <REPORT>) {
    chomp $line;
    $line_no++;
    my @words = split(/\t/, $line);

    if($words[0] eq 'BEGIN' && $words[1] eq 'Parameters') {
				# Ignore parameters
      while($line = <REPORT>) {
	chomp $line;
	$line_no++;
	@words = split(/\t/, $line);

	last if($words[0] eq 'END' && $words[1] eq 'Parameters');
      }
    }
    elsif($words[0] eq 'BEGIN' && $words[1] eq 'Report for end of year:') {
      my $year = $words[2];

      while($line = <REPORT>) {
	chomp $line;
	$line_no++;
	@words = split(/\t/, $line);

	if($words[0] eq 'BEGIN' && $words[1] eq $report) {
	  my @data;

	  if(defined($years{$year})) {
	    die "Invalid format in report file $report_file, line $line_no: "
	      ."Two instances of report $report in year $year\n";
	  }

	  while($line = <REPORT>) {
	    chomp $line;
	    $line_no++;
	    @words = split(/\t/, $line);

	    if($words[0] eq 'END' && $words[1] eq $report) {
	      last;
	    }
	    else {
	      push(@data, [ @words ]);
	    }
	  }

	  $years{$year} = \@data;
	}
	elsif($words[0] eq 'BEGIN') {
	  my $ignore_report = $words[1];

	  while($line = <REPORT>) {
	    chomp $line;
	    $line_no++;
	    @words = split(/\t/, $line);

	    if($words[0] eq 'END' && $words[1] eq $ignore_report) {
	      last;
	    }
	  }
	}
	elsif($words[0] eq 'END' && $words[1] eq 'Report for end of year:'
	       && $words[2] eq $year) {
	  last;
	}
	else {
	  die "Invalid format in report file $report_file, line $line_no: "
	    ."expecting BEGIN <report> or END <reports for year $year>, "
	      ."found $line\n";
	}
      }
    }
    else {
      die "Invalid format in report file $report_file, line $line_no: "
	."expecting BEGIN <report for year> or BEGIN Parameters, found "
	  ."$line\n";
    }
  }

  return %years;
}

# read_lspp
#
# Reads the LSPP CSV file (the CSV file that gives, for each step, the
# list of species on each patch, with one line per species-patch-step),
# and returns an associative array of year (step) to another associative
# array of species id to number of patches occupied.

sub read_lspp {
  my ($lspp_file) = @_;

  open(LSPP, "<$lspp_file") or die "Cannot open list species file "
    ."$lspp_file: $!\n";

  my $line;
  my $line_no = 0;

  if(!($line = <LSPP>)) {
    die "Unexpected end of file in list species file $lspp_file, line "
      ."$line_no\n";
  }
				# ignore the first line
  $line_no++;

  my %years;
  my %patch_years;
  my %year0_spp;

  while($line = <LSPP>) {
    chomp $line;
    $line_no++;

    my @cells = split(/,/, $line);

    if(scalar(@cells) < 3) {
      die "Unexpected format of list species file $lspp_file, line "
	."$line_no: not enough columns\n";
    }
    elsif(scalar(@cells) > 3) {
      warn "Ignoring data in columns 4 onwards in list species file "
	."$lspp_file, line $line_no\n";
    }

    my $year = $cells[0];
    my $patch = $cells[1];
    my $spp = $cells[2];

    if(defined($patch_years{$year,$patch,$spp})) {
      next if $year == 0;	# Ignore this issue in year 0, where
                                # it seems the data are duplicated
      die "Error in list species file $lspp_file, line $line_no ($line): "
	."Species $spp has already been stated as present on patch $patch in "
	  ."year $year on line $patch_years{$year,$patch,$spp}\n";
    }
    $patch_years{$year,$patch,$spp} = $line_no;

    if($year == 0 && !defined($year0_spp{$spp})) {
      $year0_spp{$spp} = 1;
    }

    if(defined($years{$year}->{$spp})) {
      $years{$year}->{$spp}++;
    }
    elsif(defined($years{$year})) {
      $years{$year}->{$spp} = 1;
    }
    else {
      my %spps;

      $spps{$spp} = 1;

      $years{$year} = \%spps;
    }
  }

  # Work out the number of species present in year 0

  my $nspp = scalar(keys(%year0_spp));

  for(my $i = 1; $i <= $nspp; $i++) {
    if(!defined($year0_spp{$i})) {
      warn "Species ID $i not present in year 0 of list species file "
	."$lspp_file\n";
    }
  }

  return ($nspp, %years);
}
