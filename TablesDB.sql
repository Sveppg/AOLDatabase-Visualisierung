CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_type VARCHAR(50) NOT NULL
);


INSERT INTO users VALUES (1, 'Veteran');
INSERT INTO users VALUES (2, 'Civilian');
INSERT INTO users VALUES (3, 'Unknown');


CREATE TABLE search_query (
    search_id INT PRIMARY KEY,
    query_text VARCHAR(500) NOT NULL,
    query_time TIMESTAMP NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
);


INSERT INTO search_query VALUES 
(101, 'iraq war truth', '2006-04-12 10:15:00', 1),
(102, 'wmd iraq evidence', '2006-04-13 14:20:00', 2),
(103, 'help for ptsd soldiers', '2006-05-01 09:30:00', 1);


CREATE TABLE click (
    click_id INT PRIMARY KEY,
    search_id INT NOT NULL,
    item_rank INT,
    click_url VARCHAR(500),
    FOREIGN KEY (search_id) REFERENCES search_query(search_id)
        ON DELETE CASCADE
);


INSERT INTO click VALUES
(1, 101, 3, 'http://example.com/article1'),
(2, 102, 1, 'http://example.com/wmd'),
(3, 103, 2, 'http://example.com/ptsd-help');


CREATE TABLE keyword (
    keyword_id INT PRIMARY KEY,
    word VARCHAR(100) NOT NULL,
    category VARCHAR(100)
);


INSERT INTO keyword VALUES
(1, 'iraq', 'IRAQ_LOCATION'),
(2, 'wmd', 'WEAPON'),
(3, 'ptsd', 'VETERAN');



CREATE TABLE actor (
    actor_id INT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(100) NOT null
);

INSERT INTO actor VALUES
(1, 'George Bush', 'Politician'),
(2, 'Saddam Hussein', 'Politician'),
(3, 'United Nations', 'Organization');

CREATE TABLE query_keyword (
    search_id INT NOT NULL,
    keyword_id INT NOT NULL,
    PRIMARY KEY (search_id, keyword_id),
    FOREIGN KEY (search_id) REFERENCES search_query(search_id)
        ON DELETE CASCADE,
    FOREIGN KEY (keyword_id) REFERENCES keyword(keyword_id)
        ON DELETE CASCADE
);

INSERT INTO query_keyword VALUES 
(101, 1),  -- iraq
(102, 2),  -- wmd
(103, 3);  -- pts

CREATE TABLE query_actor (
    search_id INT NOT NULL,
    actor_id INT NOT NULL,
    PRIMARY KEY (search_id, actor_id),
    FOREIGN KEY (search_id) REFERENCES search_query(search_id)
        ON DELETE CASCADE,
    FOREIGN KEY (actor_id) REFERENCES actor(actor_id)
        ON DELETE CASCADE
);

-- Beispiel: Saddam in Query 101, Bush in 102, UN in 103
INSERT INTO query_actor VALUES
(101, 2),
(102, 1),
(103, 3);

