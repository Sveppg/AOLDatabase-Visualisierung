-- processing -> inserts mit schlüsselwort

INSERT INTO keyword (keyword_id, word, category) VALUES
(100, 'iraq',           'IRAQ_LOCATION'),   -- redundanter Eintrag ok, zur Sicherheit
(101, 'baghdad',        'IRAQ_LOCATION'),
(102, 'basra',          'IRAQ_LOCATION'),
(103, 'mosul',          'IRAQ_LOCATION'),
(110, 'war',            'WAR'),
(111, 'invasion',       'WAR'),
(112, 'troops',         'WAR'),
(113, 'bombing',        'WAR'),
(120, 'ied',            'WEAPON'),
(121, 'improvised explosive device', 'WEAPON'),
(122, 'roadside bomb',  'WEAPON'),
(123, 'wmd',            'WEAPON'),
(124, 'nuclear weapons','WEAPON'),
(125, 'chemical weapons','WEAPON'),
(126, 'uranium',        'WEAPON'),
(130, 'ptsd',           'VETERAN'),
(131, 'veteran',        'VETERAN'),
(132, 'help',           'VETERAN'),
(133, 'support',        'VETERAN'),
(134, 'weapons of mass destruction','WEAPON'),
(135, 'london' ,'WORLD_LOCATION'),
(136, 'berlin' ,'WORLD_LOCATION'),
(137, 'warsaw' ,'WORLD_LOCATION'),
(138, 'Stockholm' ,'WORLD_LOCATION');

-- gleiche für aktor
INSERT INTO actor (actor_id, name, type) VALUES
(100, 'George Bush', 'Politician'),        
(101, 'Saddam Hussein', 'Politician'),
(102, 'Dick Cheney', 'Politician'),
(103, 'Benjamin Netanyahu', 'Politician'),
(104, 'United Nations', 'Organization');



INSERT INTO query_keyword (search_id, keyword_id)
SELECT 
    sq.search_id,
    k.keyword_id
FROM search_query sq
JOIN keyword k
  ON LOWER(sq.query_text) LIKE '%' || LOWER(k.word) || '%'
ON CONFLICT DO NOTHING;

-- listen auto befüllen
INSERT INTO query_actor (search_id, actor_id)
SELECT
    sq.search_id,
    a.actor_id
FROM search_query sq
JOIN actor a
  ON LOWER(sq.query_text) LIKE '%' || LOWER(a.name) || '%'
ON CONFLICT DO NOTHING;


