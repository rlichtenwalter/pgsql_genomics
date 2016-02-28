DROP TABLE IF EXISTS variant;

CREATE TABLE variant (
	pk					SERIAL			PRIMARY KEY,
	name				VARCHAR			UNIQUE,
	reference_allele	VARCHAR			NOT NULL,
	alternate_allele	VARCHAR			NOT NULL
);

ALTER TABLE variant DROP CONSTRAINT variant_name_key;
ALTER TABLE variant DROP CONSTRAINT variant_pkey;
\! rm -rf /tmp/psql_pipe && mkdir -p /tmp/psql_pipe && mkfifo -m 600 /tmp/psql_pipe/x && (< ./dml/INSERT_variant.sql.gz gunzip > /tmp/psql_pipe/x &)
\i /tmp/psql_pipe/x
\! rm -rf /tmp/psql_pipe
ALTER TABLE variant ADD PRIMARY KEY (pk) WITH (FILLFACTOR = 100);
ALTER TABLE variant ADD UNIQUE(name) WITH (FILLFACTOR = 100);

CLUSTER variant USING variant_pkey;
VACUUM FULL ANALYZE variant;
