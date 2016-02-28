CREATE OR REPLACE FUNCTION genotype_normalized_boundaries() RETURNS TABLE (
	index INTEGER,
	lower INTEGER,
	upper INTEGER
) AS $$
SELECT
	series.index::INTEGER AS index,
	series.value AS lower,
	series.value + (SELECT CEIL((MAX(pk)+1)/64::REAL)::INTEGER FROM variant) AS upper
FROM
	GENERATE_SERIES( 
			(SELECT MIN(pk) FROM variant),
			(SELECT MAX(pk)+1 FROM variant),
			(SELECT CEIL((MAX(pk)+1)/64::REAL)::INTEGER FROM variant)
			) WITH ORDINALITY AS series(value,index)
;
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION create_genotype_normalized_partitions() RETURNS VOID AS $$
DECLARE
	_i RECORD;
	_table_name TEXT;
BEGIN
	FOR _i IN SELECT * FROM genotype_normalized_boundaries() LOOP
		_table_name := QUOTE_IDENT( 'genotype_normalized_' || _i.index );
		EXECUTE 'CREATE UNLOGGED TABLE ' || _table_name || '(CHECK (variant_ref >= ' || _i.lower || ' AND variant_ref < ' || _i.upper || ' )) INHERITS (genotype_normalized)';
	END LOOP;
	RETURN;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drop_genotype_normalized_partitions() RETURNS VOID AS $$
DECLARE
	_i RECORD;
	_table_name TEXT;
BEGIN
	FOR _i IN SELECT * FROM genotype_normalized_boundaries() LOOP
		_table_name := QUOTE_IDENT( 'genotype_normalized_' || _i.index );
		EXECUTE 'DROP TABLE IF EXISTS ' || _table_name;
	END LOOP;
	RETURN;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fill_genotype_normalized_partitions()
RETURNS VOID AS $$
DECLARE
	_variant_ref INTEGER;
	_table_name TEXT;
BEGIN
	FOR _variant_ref IN SELECT variant_ref FROM genotype_array_vm LOOP
		_table_name := QUOTE_IDENT( 'genotype_normalized_' || (SELECT (_variant_ref - 1) / CEIL((MAX(pk)+1)/64::REAL)::INTEGER + 1 FROM variant) );
		EXECUTE 'INSERT INTO ' || _table_name || ' (sample_ref,variant_ref,genotype) ' ||
				'SELECT x.array_index,genotype_array_vm.variant_ref,x.genotype ' ||
				'FROM genotype_array_vm,UNNEST(genotypes) WITH ORDINALITY x(genotype,array_index) ' ||
				'WHERE genotype_array_vm.variant_ref = ' || _variant_ref || ' AND x.genotype IS NOT NULL';
	END LOOP;
	RETURN;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finalize_genotype_normalized_partitions() RETURNS VOID AS $$
DECLARE
	_i RECORD;
	_table_name TEXT;
BEGIN
	FOR _i IN SELECT * FROM genotype_normalized_boundaries() LOOP 
		_table_name := QUOTE_IDENT( 'genotype_normalized_' || _i.index );
		EXECUTE 'ALTER TABLE ' || _table_name || ' ADD PRIMARY KEY (variant_ref,sample_ref) WITH (FILLFACTOR = 100)';
		EXECUTE 'ALTER TABLE ' || _table_name || ' ADD FOREIGN KEY (sample_ref) REFERENCES sample(pk)';
		EXECUTE 'ALTER TABLE ' || _table_name || ' ADD FOREIGN KEY (variant_ref) REFERENCES variant(pk)';
		EXECUTE 'CLUSTER ' || _table_name || ' USING ' || QUOTE_IDENT( _table_name || '_pkey' );
	END LOOP;
END
$$ LANGUAGE plpgsql;

SELECT drop_genotype_normalized_partitions();
DROP TABLE IF EXISTS genotype_normalized;

CREATE UNLOGGED TABLE genotype_normalized (
	sample_ref		INTEGER			NOT NULL,
	variant_ref		INTEGER			NOT NULL,
	genotype		tinyint			NULL,
	FOREIGN KEY (sample_ref) REFERENCES sample(pk),
	FOREIGN KEY (variant_ref) REFERENCES variant(pk)
);

SELECT create_genotype_normalized_partitions();
SELECT fill_genotype_normalized_partitions();
SELECT finalize_genotype_normalized_partitions();
