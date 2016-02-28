#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

srand( 1 );
my $nsamples = 3104;
my $nvariants = 2567845;

my $maf = 0.20;
my $one = 1 - $maf;
my $two = 1 - $maf*$maf;

print "CHR\tSNP\t(C)M\tPOS\tCOUNTED\tALT";
for( my $sample_id = 1; $sample_id <= $nsamples; ++$sample_id ) {
	print "\t$sample_id";
}
print "\n";
for( my $variant_id = 1; $variant_id <= $nvariants; ++$variant_id ) {
	printf "0\trs$variant_id\t0\t0\tA\tC";
	for( my $sample_id = 1; $sample_id <= $nsamples; ++$sample_id ) {
        my $randval = rand();
        if( $randval > $two ) {
            printf "\t2";
        } elsif( $randval > $one ) {
            printf "\t1";
        } else {
            printf "\t0";
        }
	}
	print "\n";
}

