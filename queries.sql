CREATE OR REPLACE VIEW veteran_help_queries_raw AS
SELECT DISTINCT 
    ar.anonid,
    ar.query,
    ar.querytime,
    k.word AS matched_keyword
FROM aol_raw ar
JOIN keyword k 
    ON k.category = 'VETERAN'
   AND ar.query ~* (
        '(^|[^A-Za-z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^A-Za-z0-9]|$)'
   );

-- wie oft wurden IED's erwähnt?
SELECT
    COUNT(*) FILTER (
        WHERE query ~* '(^|[^a-z0-9])(ied|improvised explosive device|roadside bomb)([^a-z0-9]|$)'
    ) AS mention_count,

    COUNT(*) AS total_queries,
    ROUND(
        1000000.0 * COUNT(*) FILTER (
            WHERE query ~* '(^|[^a-z0-9])(ied|improvised explosive device|roadside bomb)([^a-z0-9]|$)'
        ) / COUNT(*)
    , 3) as ppm
FROM aol_raw;

SELECT *
FROM aol_raw
WHERE query ~* '(^|[^a-z0-9])(ied|improvised explosive device|roadside bomb)([^a-z0-9]|$)';




-- Welche Politiker kamen in Verbindung mit Irak vor?
SELECT
    a.name AS politician,
    COUNT(*) AS mention_count
FROM aol_raw ar
JOIN actor a
  ON ar.query ~* (
        '(^|[^a-zA-Z0-9])' ||
        regexp_replace(a.name, ' ', '\\s+', 'g') ||
        '([^a-zA-Z0-9]|$)'
     )
JOIN keyword k
  ON k.category = 'IRAQ_LOCATION'
 AND ar.query ~* (
        '(^|[^a-zA-Z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^a-zA-Z0-9]|$)'
     )
WHERE a.type = 'Politician'
GROUP BY a.name
ORDER BY mention_count DESC;



--Welche Themenbegriffe (z. B. Bagdad, US-Truppen, Zivilisten) kamen am häufigsten vor?
SELECT
    k.word AS keyword,
    k.category,
    COUNT(*) AS mention_count
FROM aol_raw ar
JOIN keyword k
  ON ar.query ~* (
        '(^|[^a-zA-Z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^a-zA-Z0-9]|$)'
     )
GROUP BY k.word, k.category
ORDER BY mention_count DESC;


-- welche akteure  (bush, husain, UN) wurden am häufigsten erwähnt?
select 
	a.name as name,
	a.type,
	count(*) as mention_count
from aol_raw ar
join actor a
	on ar.query ~* (
        '(^|[^a-zA-Z0-9])' ||
        regexp_replace(a.name, ' ', '\\s+', 'g') ||
        '([^a-zA-Z0-9]|$)'
     )
group by a.name, a.type
order by mention_count desc;

--Wie viele Veteranen haben online nach Hilfe gesucht? (indirekt)
WITH veteran_queries AS (
  SELECT DISTINCT ar.anonid, ar.querytime, ar.query
  FROM aol_raw ar
  WHERE EXISTS (
    SELECT 1 FROM keyword k
    WHERE k.category='VETERAN'
      AND ar.query ~* (
        '(^|[^A-Za-z0-9])' ||
        regexp_replace(k.word, ' ', '\s+', 'g') ||
        '([^A-Za-z0-9]|$)'
      )
  )
),
veteran_help_queries AS (
  SELECT *
  FROM veteran_queries
  WHERE query ~* '(^|[^A-Za-z0-9])(help|support|therapy|counsel(ing)?|clinic|hospital|va|hotline|treatment)([^A-Za-z0-9]|$)'
)
SELECT
  (SELECT COUNT(*) FROM veteran_queries)      AS veteran_related,
  (SELECT COUNT(*) FROM veteran_help_queries) AS veteran_help,
  ROUND(
    100.0 * (SELECT COUNT(*) FROM veteran_help_queries)::numeric
    / NULLIF((SELECT COUNT(*) FROM veteran_queries),0)::numeric
  , 2) AS pct_help_within_veteran;


--Wie viele der Suchen nach Irak waren in Verbindung zum Krieg?
WITH iraq_queries AS (
    SELECT DISTINCT ar.*
    FROM aol_raw ar
    JOIN keyword k ON k.category = 'IRAQ_LOCATION'
     AND ar.query ~* (
            '(^|[^a-zA-Z0-9])' ||
            regexp_replace(k.word, ' ', '\\s+', 'g') ||
            '([^a-zA-Z0-9]|$)'
         )
),

iraq_war_queries AS (
    SELECT DISTINCT ar.*
    FROM aol_raw ar
    JOIN keyword k1 ON k1.category = 'IRAQ_LOCATION'
     AND ar.query ~* (
            '(^|[^a-zA-Z0-9])' ||
            regexp_replace(k1.word, ' ', '\\s+', 'g') ||
            '([^a-zA-Z0-9]|$)'
         )
    JOIN keyword k2 ON k2.category IN ('WAR', 'WEAPON')
     AND ar.query ~* (
            '(^|[^a-zA-Z0-9])' ||
            regexp_replace(k2.word, ' ', '\\s+', 'g') ||
            '([^a-zA-Z0-9]|$)'
         )
)

SELECT
    (SELECT COUNT(*) FROM iraq_war_queries) AS iraq_war_queries,
    (SELECT COUNT(*) FROM iraq_queries) AS total_iraq_queries,
    ROUND(
        (SELECT COUNT(*) FROM iraq_war_queries)::NUMERIC /
        (SELECT COUNT(*) FROM iraq_queries)::NUMERIC * 100,
        2
    ) AS percent_iraq_war;

--Wie oft wurde nach den Atomwaffen (WMD etc.) gesucht?
CREATE OR REPLACE VIEW wmd_queries_raw AS
SELECT DISTINCT 
    ar.anonid,
    ar.query,
    ar.querytime,
    k.word AS matched_keyword
FROM aol_raw ar
JOIN keyword k
   ON k.category = 'WEAPON'
  AND ar.query ~* (
        '(^|[^A-Za-z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^A-Za-z0-9]|$)'
     );

SELECT
    matched_keyword,
    COUNT(*) AS mention_count
FROM wmd_queries_raw
GROUP BY matched_keyword
ORDER BY mention_count DESC;


-- Welche Suchanfragen enthalten Routen- oder Navigationsangaben zu irakischen Orten
SELECT
    k.word AS iraq_city,
    DATE_TRUNC('month', ar.querytime) AS month,
    COUNT(*) AS mention_count
FROM aol_raw ar
JOIN keyword k
  ON k.category = 'IRAQ_LOCATION'
 AND ar.query ~* (
        '(^|[^A-Za-z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^A-Za-z0-9]|$)'
     )
GROUP BY k.word, DATE_TRUNC('month', ar.querytime)
ORDER BY k.word, month;



--Welche Queries enthalten Routen-/Navigationsangaben (from X to Y, directions to …)?
SELECT DISTINCT
    ar.anonid,
    ar.query,
    ar.querytime,
    k.word AS iraq_city
FROM aol_raw ar
JOIN keyword k
  ON k.category = 'IRAQ_LOCATION'
 AND ar.query ~* (
        '(^|[^A-Za-z0-9])' ||
        regexp_replace(k.word, ' ', '\\s+', 'g') ||
        '([^A-Za-z0-9]|$)'
     )
WHERE
       ar.query ~* 'from .+ to .+'
    OR ar.query ~* 'directions to'
    OR ar.query ~* 'route to'
    OR ar.query ~* 'how to get to';


--Internationale Ortskombinationen (Irak + Ausland)
WITH iraq_hits AS (
    SELECT 
        ar.anonid,
        ar.query,
        ar.querytime,
        k.word AS iraq_city
    FROM aol_raw ar
    JOIN keyword k 
      ON k.category = 'IRAQ_LOCATION'
     AND ar.query ~* (
            '(^|[^A-Za-z0-9])' ||
            regexp_replace(k.word, ' ', '\\s+', 'g') ||
            '([^A-Za-z0-9]|$)'
         )
),

world_hits AS (
    SELECT 
        ar.anonid,
        ar.query,
        ar.querytime,
        k.word AS world_city
    FROM aol_raw ar
    JOIN keyword k 
      ON k.category = 'WORLD_LOCATION'
     AND ar.query ~* (
            '(^|[^A-Za-z0-9])' ||
            regexp_replace(k.word, ' ', '\\s+', 'g') ||
            '([^A-Za-z0-9]|$)'
         )
)

SELECT
    ih.iraq_city,
    wh.world_city,
    COUNT(*) AS mention_count
FROM iraq_hits ih
JOIN world_hits wh
  ON ih.anonid = wh.anonid
GROUP BY ih.iraq_city, wh.world_city
ORDER BY mention_count DESC;


