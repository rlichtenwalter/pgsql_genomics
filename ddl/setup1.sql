\connect postgres

DROP DATABASE pgsql_genomics;
DROP ROLE pgsql_genomics_owner;

CREATE ROLE pgsql_genomics_owner WITH
    LOGIN
    CREATEROLE
    ENCRYPTED PASSWORD 'password'
    ;
CREATE DATABASE pgsql_genomics
    WITH OWNER = pgsql_genomics_owner
    ENCODING = 'UTF-8'
    ;

\connect pgsql_genomics

CREATE EXTENSION IF NOT EXISTS HSTORE;

CREATE TYPE imputed_genotype;

CREATE FUNCTION imputed_genotype_in( CSTRING )
	RETURNS imputed_genotype
	AS '$libdir/user_defined/imputed_genotype'
	LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION imputed_genotype_out( imputed_genotype )
	RETURNS CSTRING
	AS '$libdir/user_defined/imputed_genotype'
	LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE imputed_genotype (
	INPUT = imputed_genotype_in,
	OUTPUT = imputed_genotype_out,
	INTERNALLENGTH = 4,
	PASSEDBYVALUE,
	ALIGNMENT = int4
);

CREATE OR REPLACE FUNCTION array_multi_index( ANYARRAY, INTEGER[] )
    RETURNS ANYARRAY
    AS '$libdir/user_defined/array_multi_index'
    LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE variant_data AS (
	call_rate REAL,
	subset_call_rate REAL,
	maf REAL,
	subset_maf REAL
);

