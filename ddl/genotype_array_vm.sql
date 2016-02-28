DROP TABLE IF EXISTS genotype_array_vm;

CREATE TABLE genotype_array_vm (
	variant_ref				INTEGER			PRIMARY KEY,
	genotypes				tinyint[]		NOT NULL,
	FOREIGN KEY (variant_ref) REFERENCES variant(pk)
);

ALTER TABLE genotype_array_vm DROP CONSTRAINT genotype_array_vm_variant_ref_fkey;
ALTER TABLE genotype_array_vm DROP CONSTRAINT genotype_array_vm_pkey;
\! rm -rf /tmp/psql_pipe && mkdir -p /tmp/psql_pipe && mkfifo -m 600 /tmp/psql_pipe/x && (< ./dml/INSERT_genotype_array_vm.sql.gz gunzip > /tmp/psql_pipe/x &)
\i /tmp/psql_pipe/x
\! rm -rf /tmp/psql_pipe
ALTER TABLE genotype_array_vm ADD PRIMARY KEY (variant_ref) WITH (FILLFACTOR = 100);
ALTER TABLE genotype_array_vm ADD FOREIGN KEY (variant_ref) REFERENCES variant(pk);

CLUSTER genotype_array_vm USING genotype_array_vm_pkey;
VACUUM FULL ANALYZE genotype_array_vm;
