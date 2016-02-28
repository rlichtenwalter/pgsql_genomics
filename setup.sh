#! /bin/sh

# install extensions into PostgreSQL
command -v pg_config > /dev/null 2>&1 || { printf "Command 'pg_config' is required but not found in path. Make sure PostgreSQL client tools are installed. Aborting.\n" 1>&2; exit 1; }
pg_libdir="$(pg_config --pkglibdir)"
pg_installdir="$pg_libdir/pgsql_genomics"
mkdir -p -m 755 "$pg_installdir" || { printf "Unable to create directory '$pg_installdir' for installation into PostgreSQL. Aborting.\n" 1>&2 exit 1; }
(
	cd ./c &&
	make &&
	cp array_multi_index.so imputed_genotype.so summarize_variant.so "$pg_installdir" &&
	chmod -R 755 "$pg_installdir"
)
(
	cd ./lib/tinyint-0.1.1 &&
	make &&
	sed -i -e '1i\\\connect pgsql_genomics' -e 's|$libdir\/tinyint|$libdir/pgsql_genomics/tinyint|g' tinyint.sql &&
	cp tinyint.so "$pg_installdir" &&
	chmod -R 755 "$pg_installdir"
)

# generate fake data and SQL DML statements to load the database
{ ./dat_gen/gen_raw.pl || { printf "Procedure for 'raw' data file generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dat/raw.gz
{ ./dat_gen/gen_traw.pl || { printf "Procedure for 'traw' data file generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dat/traw.gz
{ ./dml_gen/sample.pl || { printf "Procedure for 'sample' table DML generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dml/INSERT_sample.sql.gz
{ ./dml_gen/variant.pl || { printf "Procedure for 'variant' table DML generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dml/INSERT_variant.sql.gz
{ ./dml_gen/genotype_array_sm.pl || { printf "Procedure for 'genotype_array_sm' table DML generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dml/INSERT_genotype_array_sm.sql.gz
{ ./dml_gen/genotype_array_vm.pl || { printf "Procedure for 'genotype_array_vm' table DML generation failed. Aborting.\n" 1>&2; exit 1; } } | gzip > ./dml/INSERT_genotype_array_vm.sql.gz

# create the database and load the data
psql -q -U postgres -f ./ddl/setup1.sql || { printf "Unable to perform setup for 'pgsql_genomics' database as user 'postgres'. Check UNIX account privileges and pg_hba.conf. Aborting.\n" 1>&2; exit 1; }
psql -q -U postgres -f ./lib/tinyint-0.1.1/tinyint.sql || { printf "Unable to add 'tinyint' type to database 'pgsql_genomics'. Aborting.\n" 1>&2; exit 1; }
psql -q -U postgres -f ./ddl/setup2.sql || { printf "Unable to perform setup for 'pgsql_genomics' database as user 'postgres'. Check UNIX account privileges and pg_hba.conf. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/functions.sql || { printf "Unable to create SQL functions. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/sample.sql || { printf "Unable to create and fill 'sample' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/variant.sql || { printf "Unable to create and fill 'variant' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/genotype_array_sm.sql || { printf "Unable to create and fill 'genotype_array_sm' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/genotype_array_vm.sql || { printf "Unable to create and fill 'genotype_array_vm' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/genotype_string_sm.sql || { printf "Unable to create and fill 'genotype_string_sm' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/genotype_hstore_sm.sql || { printf "Unable to create and fill 'genotype_hstore_sm' table. Aborting.\n" 1>&2; exit 1; }
psql -q -U pgsql_genomics_owner -d pgsql_genomics -f ./ddl/genotype_normalized.sql || { printf "Unable to create and fill 'genotype_normalized' table. Aborting.\n" 1>&2; exit 1; }

