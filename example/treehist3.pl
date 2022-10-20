#!/usr/bin/perl
#
# treehist2.pl
#
# Gary Polhill, 19 June 2012
#
# Script to use R to draw a classification tree of some variables, and then draw
# boxplots of species and land use occupancy.
#
# Usage: ./treehist.pl <data file> <PDF> <response var> <explanatory vars (comma sep)>
#       <histogram vars (comma sep)>

use strict;
use File::Path qw(remove_tree);

#my $R = '/usr/local/bin/R';
my $R = '/usr/bin/R';
my @Rargs = ('--vanilla');
my $tmp = '/var/tmp';
my $asfactor = 1;
my $cex = 0.67;
my $bcex = 1;
my $uniform = "F";
my $margin = 0;
my $size = 1.5;
my $cp = 0.01;
my @box = ( { 'Occupancy.SPP.1' => 'G1',
	      'Occupancy.SPP.2' => 'G2',
	      'Occupancy.SPP.3' => 'G3',
	      'Occupancy.SPP.4' => 'G4',
	      'Occupancy.SPP.5' => 'G5',
	      'Occupancy.SPP.6' => 'G6',
	      'Occupancy.SPP.7' => 'A1',
	      'Occupancy.SPP.8' => 'A2',
	      'Occupancy.SPP.9' => 'A3',
	      'Occupancy.SPP.10' => 'C' },
	    { 'Occupancy.LU.1' => 'GL1',
	      'Occupancy.LU.2' => 'GL2',
	      'Occupancy.LU.3' => 'GL3',
	      'Occupancy.LU.4' => 'AL1',
	      'Occupancy.LU.5' => 'AL2',
	      'Occupancy.LU.6' => 'AL3' } );

while($ARGV[0] =~ /^-/) {
  my $opt = shift(@ARGV);

  if($opt eq '-R') {
    $R = shift(@ARGV);
  }
  elsif($opt eq '-Rargs') {
    @Rargs = split(/,/, shift(@ARGV));
  }
  elsif($opt eq '-tmp') {
    $tmp = shift(@ARGV);
  }
  elsif($opt eq '-asfactor') {
    $asfactor = 0;
  }
  elsif($opt eq '-cex') {
    $cex = shift(@ARGV);
  }
  elsif($opt eq '-bcex') {
    $bcex = shift(@ARGV);
  }
  elsif($opt eq '-uniform') {
    $uniform = 'T';
  }
  elsif($opt eq '-margin') {
    $margin = shift(@ARGV);
  }
  elsif($opt eq '-cp') {
    $cp = shift(@ARGV);
  }
  elsif($opt eq '-size') {
    $size = shift(@ARGV);
  }
  else {
    die "Unrecognised option $opt\n";
  }
}

if(scalar(@ARGV) != 4) {
  die "Usage: $0 [-R <location of R>] [-Rargs <comma-separated list of R arguments>]",
    " [-tmp <location of temporary directory>] [-asfactor] ",
      "<Data file> <PDF output> <response variable> <comma-separated list ",
	"of explanatory variables>\n\n-asfactor means don't treat the ",
	    "response variable as a factor\n";
}

my $file = shift(@ARGV);
my $pdf = shift(@ARGV);
my $response = shift(@ARGV);
my $explanatory = join(" + ", split(/,/, shift(@ARGV)));

my $rcmd = join(" ", $R, @Rargs);

my $responsevar = $response;
$response = "as.factor($response)" if $asfactor;

# Create a temporary working directory

my $dir = "$tmp/treehist.$$";

mkdir($dir) or die "Cannot create temporary directory $dir: $!\n";

# First we need to get a printout of the tree

my $treeprintfile = "$dir/treeprint.txt";
my $treefile = "$dir/tree.txt";

open(R, "| $rcmd") or &croak("Cannot open a pipe to R (\"$rcmd\"): $!\n", $dir);

print R "require(\"rpart\")\n";
print R "data <- read.table(\"$file\", header = T, sep = \",\")\n";
print R "data\$X <- data\$Expenditure\n";
print R "tree <- rpart($response ~ $explanatory, data = data, method = \"class\", ",
  "control = rpart.control(cp = $cp))\n";
print R "save(tree, file = \"$treefile\", ascii = T)\n";
print R "sink(\"$treeprintfile\")\n";
print R "print(tree)\n";
print R "sink()\n";
print R "quit(save = \"no\")\n";

close(R) or warn "Cannot close pipe to R: $!\n";

# Now we need to parse the tree and get the leaf node data

my @leaves;

open(TREE, "<$treeprintfile")
  or &croak("Cannot open tree print file $treeprintfile: $!\n", $dir);

my @stack;
my $previndent;
my %indents;

while(my $line = <TREE>) {
  if($line =~ /^(\s+)(\d+)\)\s+(.*)\s*$/) {
    my ($indent, $nodeid, $data) = ($1, $2, $3);
    $data =~ s/\<\s/\</;
    my ($split, $n, $loss, $yval) = split(" ", $data);

    if($split =~ /,/) {
      my ($var, $valuestr) = split(/=/, $split);
      my @values = &quote(split(/,/, $valuestr));
      $split = "($var==".join(" | $var==", @values).")";
    }
    else {
      ($split) = &quote($split);
    }

    my $lindent = length($indent);
    $indents{$split} = $lindent;

    $previndent = $lindent if(!defined($previndent));

    if($lindent > $previndent) {
      push(@stack, $split);
    }
    elsif($lindent == $previndent) {
      if(scalar(@stack) > 0) {
	pop(@stack);
	push(@stack, $split);
      }
      elsif($split ne 'root' && $split ne '"root"') {
	warn "Empty stack and \$split = $split (not 'root')\n";
      }
    }
    else {
      while(scalar(@stack) > 0) {
	my $osplit = pop(@stack);
	if($indents{$osplit} == $lindent) {
	  push(@stack, $split);
	  last;
	}
      }
      if(scalar(@stack) == 0) {
	&croak("Could not find a node with indent $lindent\n", $dir);
      }
    }

    if($data =~ /\*$/) {
      print "Leaf node $nodeid ($response = $yval): ", join(" & ", @stack), "\n";

      push(@leaves, [$nodeid, $yval, $n, @stack]);
    }

    $previndent = $lindent;
  }
}

close(TREE);

# Now use R to create the PDF

open(R, "| $rcmd") or &croak("Cannot open a pipe to R (\"$rcmd\"): $!\n", $dir);

print R "require(\"rpart\")\n";
print R "data <- read.table(\"$file\", header = T, sep = \",\")\n";
print R "data\$X <- data\$Expenditure\n";

for(my $i = 1; $i <= 6; $i++) {
  print R "data\$Occupancy.LU.$i <- data\$Occupancy.LU.$i / 625\n";
}

print R "load(\"$treefile\")\n";
print R "tree\n";
print R "pdf(file = \"$pdf\")\n";
print R "plot(tree, uniform = $uniform, margin = $margin)\n";
print R "text(tree, pretty = 0, cex = $cex, xpd = T)\n";

my $pdfleaves = $pdf;
$pdfleaves =~ s/\.pdf$/-leaves.pdf/;

print R "pdf(file = \"$pdfleaves\", height = $size, width = ", ($size * 3), ")\n";
print R "par(mfrow = c(1, 3), mar = c(3, 2, 1, 1))\n";

#print R "par(mfrow = c($mfrow[0], $mfrow[1]), mar = c(4, 2.5, 1, 1))\n";
foreach my $leaf (@leaves) {
  my ($nodeid, $yval, $n, @stack) = @$leaf;

  my $subset = join(" & ", @stack);

  print R "subdata <- subset(data, $subset)\n";
  print R "print(c(length(subdata[,1]), $n))\n";
  if($responsevar eq 'Richness') {
    print R "hist(subdata\$Richness, breaks = c(0:11) - 0.5, freq = F, ",
      "ylim = c(0, 1), main = \"\", xlab = \"$responsevar\", ylab = \"\", ",
	"cex.axis = $bcex, yaxt = \"n\", col = \"black\")\n";
    print R "axis(side = 2, at = c(0, 1), labels = c(0, 1), cex.axis = $bcex)\n";
  }
  elsif($responsevar =~ /^Occupancy/) {
    print R "hist(subdata\$$responsevar, breaks = 0:10 / 10, xlim = c(0, 1), ",
      "freq = F, ylim = c(0, 1), main = \"\", xlab = \"$responsevar\", ",
	"ylab = \"\", cex.axis = $bcex)\n";
  }
  else {
    print R "hist(subdata\$$responsevar, freq = F, ylim = c(0, 1), main = \"\", ",
      "xlab = \"$responsevar\", ylab = \"\", cex.axis = $bcex)\n";
  }

  foreach my $boxp (@box) {
    my @vars = sort { my @aa = split(/\./, $a);
		      my @bb = split(/\./, $b);
		      $aa[$#aa] <=> $bb[$#bb] } (keys(%$boxp));
    my @labels;
    for(my $i = 0; $i <= $#vars; $i++) {
      $labels[$i] = $boxp->{$vars[$i]};
    }

#    print R "boxplot(subdata\$", join(", subdata\$", @vars), ", ylim = c(0, 1), ",
#      "names = c(\"", join("\", \"", @labels), "\"), cex.axis = $bcex, ",
#	"outline = F)\n";
    print R "boxplot(subdata\$", join(", subdata\$", @vars), ", ylim = c(0, 1), ",
      "outline = F, axes = F, mar = c(3, 0, 1, 1))\n";
    print R "axis(side = 1, at = 1:", scalar(@vars), ", labels = c(\"",
      join("\", \"", @labels), "\"), cex.axis = $bcex, las = 2)\n";
#    print R "axis(side = 2, at = c(0, 1), labels = c(0, 1), cex.axis = $bcex)\n";
  }
}

print R "quit(save = \"no\")\n";

close(R) or warn "Cannot close pipe to R: $!\n";

# Delete the temporary working directory

remove_tree($dir);
exit 0;

# Exit under error condition, tidying up the temporary directory first

sub croak {
  my ($msg, $dir) = @_;

  remove_tree($dir);
  die "$msg";
}

sub quote {
  my @arr;

  foreach my $str (@_) {
    if($str =~ /^(\w+)([<>]=?|=)(.*)/) {
      my ($var, $op, $value) = ($1, $2, $3);

      $op = '==' if($op eq '=');
      
      if($value !~ /^[+-]?\d*\.?\d+(?:[eE][+-]?\d+)?$/) {
	$value = "\"$value\"";
      }

      $str = "$var$op$value";
    }
    elsif($str !~ /^[+-]?\d*\.?\d+(?:[eE][+-]?\d+)?$/) {
      $str = "\"$str\"";
    }
    push(@arr, $str);
  }

  return @arr;
}
