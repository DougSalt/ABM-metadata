#!/usr/bin/perl

use strict;

my $some_dir = ".";
my %container_types;
opendir(my $dh, $some_dir) || die "Can't open $some_dir: $!";
while (my $file = readdir $dh) {
	next unless $file =~ /^(.*)((_[^_]*){11})\.(.*)$/;
	my $prefix = $1;
	my $suffix = $4;
	$container_types{$prefix . "\/" . $suffix} = [ split(/_/,substr($2,1), 11) ];
}
closedir $dh;

for my $combined_key (keys %container_types) {
	my ($container_type, $suffix) = split(/\//,$combined_key);
	my $container_type_without_minus = $container_type;
	$container_type_without_minus =~ s/\-/\_/g;

#       Code producing the ContainerTypes
#	print $container_type_without_minus . "_id=\$(SSREPI_container_type $container_type \\\n";
#	print "\t\"file:$container_type";
#	for my $globby (@{$container_types{$combined_key}}) {
#		if ($globby ne "") {
#			print "_[^_]+"
#		}
#		else {
#			print "_"
#		}
#	}
#	print ".$suffix\")\n";
#	print "[ -n \"\$" . $container_type_without_minus . "_id\" ] || exit -1 \n\n";
#





#	Code producing the Product 
#	print "product_" . $container_type_without_minus . 
#		"_id=\$(SSREPI_product \\\n";
#	print "\t" . $container_type . " \\\n";
#	print "\t\$ME \\\n"; 
#	print "\t\$" . $container_type_without_minus . "_id \\\n";
#	print "\t\"CWD PATH REGEX:";
#	for my $globby (@{$container_types{$combined_key}}) {
#		if ($globby ne "") {
#			print "_[^_]+"
#		}
#		else {
#			print "_"
#		}
#	}
#	print ".$suffix\")\n";
#	print "[ -n \"\$" . $container_type_without_minus . "_id\" ] || exit -1 \n\n";








#	Output types

	print $container_type_without_minus . 
		"_id=\$(SSREPI_output_type \$ME \\\n"; 
	print "\t" . $container_type . " \\\n";
	print "\t\""; 
	for my $globby (@{$container_types{$combined_key}}) {
		if ($globby ne "") {
			print "_[^_]+"
		}
		else {
			print "_"
		}
	}
	print ".$suffix\")\n";
	print "[ -n \"\$" . $container_type_without_minus . "_id\" ] || exit -1 \n\n";




#	Outputs
#
#my @param_order = ( 'sink', 'government', 'zone', 'reward', 'cluster', 'market',
#                    'bet', 'approval', 'iwealth', 'aspiration', 'run' );
#
#	my @var = (
#        'nosink',
#        '${govt}',
#        'all',
#        '${rwd}',
#        '${rat}',
#        '${market}',
#        '${bet}',
#        'noapproval',
#        '0.0',
#        '${asp}',
#        '${run}'
#	);
#
#	print "SSREPI_output \$ME \$THIS_PROCESS \$" . $container_type_without_minus . "_id \\\n";
#	print "\t\"$container_type";
#	for (my $i = 1; $i < @{$container_types{$combined_key}}; $i++) {
#		if ($container_types{$combined_key}->[$i] ne "") {
#			print "_" . $var[$i]
#		}
#		else {
#			print "_"
#		}
#	}
#	print ".$suffix\"\n";
}
