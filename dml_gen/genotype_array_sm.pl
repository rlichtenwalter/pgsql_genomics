#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $MAX_QUERY_ROWS = 1;

my $header = "INSERT INTO genotype_array_sm (sample_ref,genotypes)\n";
$header .= "SELECT sample.pk,x.genotypes\n";
$header .= "FROM (VALUES\n";
my $footer = "\n) x (src_id,genotypes)\n";
$footer .= "INNER JOIN sample ON x.src_id = sample.src_id;\n";

my $command = "gunzip --stdout ./dat/raw.gz | dos2unix | sed -e '1d' -e 's/ NA/ NULL/g' |";
open( my $raw, $command ) or die( "unable to open '$command': $!" );
while( <$raw> ) {
	chomp;
	my @input = split( " ", $_ );
	my $src_id = $input[1];
	if( $. % $MAX_QUERY_ROWS == 1 ) {
		print $header;
	} else {
		print ",\n";
	}
	print "('$src_id',ARRAY[" . join( ",", @input[6..$#input] ) . "]::tinyint[])";
	if( $. % $MAX_QUERY_ROWS == 0 ) {
		print $footer;
	}
}
if( $. % $MAX_QUERY_ROWS != 0 ) {
	print $footer;
}
close( $raw );

