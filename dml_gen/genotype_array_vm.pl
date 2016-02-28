#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $MAX_QUERY_ROWS = 1000;

my $header = "INSERT INTO genotype_array_vm (variant_ref,genotypes)\n";
$header .= "SELECT variant.pk,x.genotypes\n";
$header .= "FROM (VALUES\n";
my $footer = "\n) x (variant_name,genotypes)\n";
$footer .= "INNER JOIN variant ON x.variant_name = variant.name;\n";

my $command = "gunzip --stdout ./dat/traw.gz | dos2unix | sed -e '1d' -e 's/\tNA/\tNULL/g' |";
open( my $raw, $command ) or die( "unable to open '$command': $!" );
while( <$raw> ) {
	chomp;
	my @input = split( " ", $_ );
	my $variant_name = $input[1];
	if( $. % $MAX_QUERY_ROWS == 1 ) {
		print $header;
	} else {
		print ",\n";
	}
	print "('$variant_name',ARRAY[" . join( ",", @input[6..$#input] ) . "]::tinyint[])";
	if( $. % $MAX_QUERY_ROWS == 0 ) {
		print $footer;
	}
}
if( $. % $MAX_QUERY_ROWS != 0 ) {
	print $footer;
}
close( $raw );

