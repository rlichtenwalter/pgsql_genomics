#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $MAX_QUERY_ROWS = 100000;

my $header = "INSERT INTO variant (name,reference_allele,alternate_allele)\n";
$header .= "SELECT x.name,x.reference_allele,x.alternate_allele\n";
$header .= "FROM (VALUES\n";
my $footer = "\n) x (name,reference_allele,alternate_allele);\n";

my $command = "gunzip --stdout ./dat/raw.gz | dos2unix | head -n 1 | cut -d ' ' -f 7- | tr ' ' '\n' |";
open( my $raw, $command ) or die( "unable to open '$command': $!" );
while( <$raw> ) {
	chomp;
	my $name = $_;
	if( $. % $MAX_QUERY_ROWS == 1 ) {
		print $header;
	} else {
		print ",\n";
	}
	print "('$name','A','C')";
	if( $. % $MAX_QUERY_ROWS == 0 ) {
		print $footer;
	}
}
if( $. % $MAX_QUERY_ROWS != 0 ) {
	print $footer;
}
close( $raw );

