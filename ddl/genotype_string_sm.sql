CREATE OR REPLACE FUNCTION fill_genotype_string_sm()
RETURNS VOID AS $$
DECLARE
	_sample_ref INTEGER;
BEGIN
	FOR _sample_ref IN SELECT sample_ref FROM genotype_array_sm LOOP
		EXECUTE 'INSERT INTO genotype_string_sm (sample_ref,genotypes) ' ||
				'SELECT ' || _sample_ref || ',genotypes ' ||
				'FROM (' ||
				'	SELECT STRING_AGG( COALESCE( OVERLAY( count_to_alleles( genotype, reference_allele, alternate_allele ) PLACING '''' FROM 2 FOR 1 ), ''00'' ), '''' ) AS genotypes ' ||
				'	FROM (' ||
				'		SELECT ROW_NUMBER() OVER () AS variant_ref,genotype ' ||
				'		FROM ( ' ||
				'			SELECT UNNEST( genotypes ) AS genotype FROM genotype_array_sm WHERE sample_ref = ' || _sample_ref ||
				'			) AS anonymous1 ' ||
				'		ORDER BY variant_ref ' ||
				'		) AS anonymous2 INNER JOIN variant ON pk = variant_ref ' ||
				'	) AS anonymous3';
	END LOOP;
	RETURN;
END
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS genotype_string_sm;

CREATE TABLE genotype_string_sm (
	sample_ref				INTEGER			NOT NULL,
	genotypes				VARCHAR			NULL
);

SELECT fill_genotype_string_sm();

ALTER TABLE genotype_string_sm ADD PRIMARY KEY (sample_ref) WITH (FILLFACTOR = 100);
ALTER TABLE genotype_string_sm ADD FOREIGN KEY (sample_ref) REFERENCES sample(pk);

CLUSTER genotype_string_sm USING genotype_string_sm_pkey;
VACUUM FULL ANALYZE genotype_string_sm;
