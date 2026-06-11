DROP TABLE IF EXISTS aol_raw CASCADE;


CREATE TABLE public.aol_raw (
    anonid INT,
    query TEXT,
    querytime TIMESTAMP,
    itemrank INT,
    clickurl TEXT
);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-01.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-02.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-03.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		QUOTE E'\b',  -- ungültiges Zeichen: garantiert NICHT in der Datei
		ESCAPE E'\b',
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-04.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-05.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-06.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
	    QUOTE E'\b',  -- ungültiges Zeichen: garantiert NICHT in der Datei
    	ESCAPE E'\b',
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-07.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		HEADER TRUE);

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-08.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '',
		QUOTE E'\b',  -- ungültiges Zeichen: garantiert NICHT in der Datei
    	ESCAPE E'\b',
		HEADER TRUE); -- geht noch nicht

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-09.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		quote E'\b',
		escape E'',
		HEADER TRUE);
		

COPY aol_raw (anonid, query, querytime, itemrank, clickurl)
FROM '/var/lib/postgres/data/user-ct-test-collection-10.txt'
WITH (FORMAT CSV, 
		DELIMITER E'\t', 
		NULL '', 
		QUOTE E'\b',
		ESCAPE E'\b',
		HEADER TRUE);


SELECT COUNT(*) FROM aol_raw;

