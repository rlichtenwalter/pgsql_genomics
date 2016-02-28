DROP TABLE IF EXISTS sample;

CREATE TABLE sample (
	pk				SERIAL			PRIMARY KEY,
	src_id			VARCHAR			UNIQUE NOT NULL
);

ALTER TABLE sample DROP CONSTRAINT sample_src_id_key;
ALTER TABLE sample DROP CONSTRAINT sample_pkey;
\! rm -rf /tmp/psql_pipe && mkdir -p /tmp/psql_pipe && mkfifo -m 600 /tmp/psql_pipe/x && (< ./dml/INSERT_sample.sql.gz gunzip > /tmp/psql_pipe/x &)
\i /tmp/psql_pipe/x
\! rm -rf /tmp/psql_pipe
ALTER TABLE sample ADD PRIMARY KEY (pk) WITH (FILLFACTOR = 100);
ALTER TABLE sample ADD UNIQUE(src_id) WITH (FILLFACTOR = 100);

CLUSTER sample USING sample_pkey;
VACUUM FULL ANALYZE sample;
