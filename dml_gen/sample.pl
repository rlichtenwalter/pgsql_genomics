#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $MAX_QUERY_ROWS = 1000000;

my $header = "INSERT INTO sample (src_id)\n";
$header .= "SELECT x.src_id\n";
$header .= "FROM (VALUES\n";
my $footer = "\n) x (src_id);\n";

my $command = "gunzip --stdout ./dat/traw.gz | dos2unix | head -n 1 | cut -f 7- | tr '\t' '\n' |";
open( my $raw, $command ) or die( "unable to open '$command': $!" );
while( <$raw> ) {
	chomp;
	my $src_id = $_;
	if( $. % $MAX_QUERY_ROWS == 1 ) {
		print $header;
	} else {
		print ",\n";
	}
	print "('$src_id')";
	if( $. % $MAX_QUERY_ROWS == 0 ) {
		print $footer;
	}
}
if( $. % $MAX_QUERY_ROWS != 0 ) {
	print $footer;
}
close( $raw );

