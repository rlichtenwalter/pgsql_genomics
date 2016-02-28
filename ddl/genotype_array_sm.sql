DROP TABLE IF EXISTS genotype_array_sm;

CREATE TABLE genotype_array_sm (
	sample_ref				INTEGER			PRIMARY KEY,
	genotypes				tinyint[]		NOT NULL,
	FOREIGN KEY (sample_ref) REFERENCES sample(pk)
);

ALTER TABLE genotype_array_sm DROP CONSTRAINT genotype_array_sm_sample_ref_fkey;
ALTER TABLE genotype_array_sm DROP CONSTRAINT genotype_array_sm_pkey;
\! rm -rf /tmp/psql_pipe && mkdir -p /tmp/psql_pipe && mkfifo -m 600 /tmp/psql_pipe/x && (< ./dml/INSERT_genotype_array_sm.sql.gz gunzip > /tmp/psql_pipe/x &)
\i /tmp/psql_pipe/x
\! rm -rf /tmp/psql_pipe
ALTER TABLE genotype_array_sm ADD PRIMARY KEY (sample_ref) WITH (FILLFACTOR = 100);
ALTER TABLE genotype_array_sm ADD FOREIGN KEY (sample_ref) REFERENCES sample(pk);

CLUSTER genotype_array_sm USING genotype_array_sm_pkey;
VACUUM FULL ANALYZE genotype_array_sm;
