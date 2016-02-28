#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

srand( 1 );
my $nsamples = 3104;
my $nvariants = 2567845;

my $maf = 0.20;
my $one = 1 - $maf;
my $two = 1 - $maf*$maf;

print "FID IID PAT MAT SEX PHENOTYPE";
for( my $variant_id = 1; $variant_id <= $nvariants; ++$variant_id ) {
	print " rs$variant_id";
}
print "\n";
for( my $sample_id = 1; $sample_id <= $nsamples; ++$sample_id ) {
	printf "$sample_id $sample_id NA NA NA -9";
	for( my $variant_id = 1; $variant_id <= $nvariants; ++$variant_id ) {
		my $randval = rand();
		if( $randval > $two ) {
			printf " 2";
		} elsif( $randval > $one ) {
			printf " 1";
		} else {
			printf " 0";
		}
	}
	print "\n";
}

