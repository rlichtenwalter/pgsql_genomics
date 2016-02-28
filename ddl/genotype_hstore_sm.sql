DROP TABLE IF EXISTS genotype_hstore_sm;

CREATE TABLE genotype_hstore_sm AS
SELECT sample_ref,array_to_hstore(genotypes) AS genotypes
FROM genotype_array_sm;

ALTER TABLE genotype_hstore_sm ADD PRIMARY KEY (sample_ref) WITH (FILLFACTOR = 100);
ALTER TABLE genotype_hstore_sm ADD FOREIGN KEY (sample_ref) REFERENCES sample(pk);

CLUSTER genotype_hstore_sm USING genotype_hstore_sm_pkey;
VACUUM FULL ANALYZE genotype_hstore_sm;
