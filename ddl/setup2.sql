\connect pgsql_genomics

CREATE OR REPLACE FUNCTION summarize_variant( TINYINT[], INTEGER[] DEFAULT NULL )
	RETURNS variant_data
	AS '$libdir/pgsql_genomics/summarize_variant'
	LANGUAGE C IMMUTABLE;
