create database Sports_Analytics

create schema sportsanalysis

create table sportsanalysis.cities(
id int primary key,
city_name varchar(100) not null
);

select * from sportsanalysis.cities

consolidated_fact


CREATE TABLE sportsanalysis.consolidated_fact (
    game_id               INTEGER,
    games_competitor_id   INTEGER,
    games_competitor_age  INTEGER,
    event_name            TEXT,
    sport_name            TEXT,
    games_year            INTEGER,
    game_name             TEXT,
    games_season          TEXT,
    games_decade          TEXT,
    game_city             TEXT,
    medal_name            TEXT,
    person_full_name      TEXT,
    person_gender         CHAR(1),
    person_height         INTEGER,
    person_weight         INTEGER,
    person_id             INTEGER,
    region_id             INTEGER,
    noc                   VARCHAR(10),
    region_name           TEXT
);

select * from sportsanalysis.consolidated_fact

SELECT COUNT(*) FROM sportsanalysis.consolidated_fact;

SELECT 'city' AS tbl, COUNT(*) FROM sportsanalysis.city
UNION ALL SELECT 'competitor_event', COUNT(*) FROM sportsanalysis.competitor_event
UNION ALL SELECT 'consolidated_fact', COUNT(*) FROM sportsanalysis.consolidated_fact
UNION ALL SELECT 'event', COUNT(*) FROM sportsanalysis.event
UNION ALL SELECT 'games', COUNT(*) FROM sportsanalysis.games
UNION ALL SELECT 'games_city', COUNT(*) FROM sportsanalysis.games_city
UNION ALL SELECT 'games_competitor', COUNT(*) FROM sportsanalysis.games_competitor
UNION ALL SELECT 'medal', COUNT(*) FROM sportsanalysis.medal
UNION ALL SELECT 'noc_region', COUNT(*) FROM sportsanalysis.noc_region
UNION ALL SELECT 'person', COUNT(*) FROM sportsanalysis.person
UNION ALL SELECT 'person_region', COUNT(*) FROM sportsanalysis.person_region
UNION ALL SELECT 'sport', COUNT(*) FROM sportsanalysis.sport;

-- EDA questions

--1.Are there any trends or patterns in the frequency of hosting Olympic Games?
select 
games_year,
lead(games_year) over( order by games_year) as next_year,
(lead(games_year) over( order by games_year)) - games_year as gap
from sportsanalysis.games

-- 2.How has the duration of Olympic Games changed over time?
SELECT
    g.games_year,
    g.season,
    COUNT(DISTINCT ce.event_id) AS events
FROM sportsanalysis.games g
JOIN sportsanalysis.games_competitor gc ON gc.games_id = g.id
JOIN sportsanalysis.competitor_event ce ON ce.competitor_id = gc.id
GROUP BY g.games_year, g.season

-- 3.Are there any notable events or occurrences associated with specific Olympic Games?
SELECT
    g.games_year,
    g.season,
    c.city_name,
    COUNT(DISTINCT gc.id) AS competitors
FROM sportsanalysis.games g
JOIN sportsanalysis.games_city gcity    ON gcity.games_id = g.id
JOIN sportsanalysis.city c              ON c.id = gcity.city_id
JOIN sportsanalysis.games_competitor gc ON gc.games_id = g.id
GROUP BY g.games_year, g.season, c.city_name
ORDER BY competitors DESC;

-- 4.Are there any emerging sports that have been recently added to the Olympics?solve as simple as
SELECT
    s.sport_name,
    MIN(g.games_year) AS yearadded
FROM sportsanalysis.sport s
JOIN sportsanalysis.event e             ON e.sport_id = s.id
JOIN sportsanalysis.competitor_event ce ON ce.event_id = e.id
JOIN sportsanalysis.games_competitor gc ON gc.id = ce.competitor_id
JOIN sportsanalysis.games g             ON g.id = gc.games_id
GROUP BY s.sport_name
HAVING MIN(g.games_year) >= 2000
ORDER BY yearadded DESC, s.sport_name;

-- 5.How has the popularity of certain sports changed over the years?
SELECT
    s.sport_name,
    g.games_year,
    COUNT(DISTINCT gc.person_id) AS participants
FROM sportsanalysis.sport s
JOIN sportsanalysis.event e             ON e.sport_id = s.id
JOIN sportsanalysis.competitor_event ce ON ce.event_id = e.id
JOIN sportsanalysis.games_competitor gc ON gc.id = ce.competitor_id
JOIN sportsanalysis.games g             ON g.id = gc.games_id
WHERE g.season = 'Summer'
GROUP BY s.sport_name, g.games_year
ORDER BY s.sport_name, g.games_year;

-- 6.Are there any sports that are specific to a particular region or culture?
SELECT * FROM (
  SELECT sport_name, region_name, athletes,
         ROUND(100.0 * athletes / NULLIF(SUM(athletes) OVER (PARTITION BY sport_name), 0), 1) AS share_pct,
         SUM(athletes) OVER (PARTITION BY sport_name) AS total,
         ROW_NUMBER() OVER (PARTITION BY sport_name ORDER BY athletes DESC) AS rn
  FROM (SELECT sport_name, region_name, COUNT(DISTINCT person_id) AS athletes
        FROM sportsanalysis.consolidated_fact
        GROUP BY sport_name, region_name) t
) x
WHERE rn = 1 AND total >= 100
ORDER BY share_pct DESC;

-- 7.Are there any sports that have a higher number of events for one gender compared to others?
SELECT s.sport_name,
       COUNT(*) FILTER (WHERE e.event_name LIKE '%Women%') AS women_events,
       COUNT(*) FILTER (WHERE e.event_name LIKE '%Men''s%'
                          AND e.event_name NOT LIKE '%Women%') AS men_events
FROM sportsanalysis.event e
JOIN sportsanalysis.sport s ON s.id = e.sport_id
GROUP BY s.sport_name
ORDER BY ABS(COUNT(*) FILTER (WHERE e.event_name LIKE '%Women%')
           - COUNT(*) FILTER (WHERE e.event_name LIKE '%Men''s%'
                                AND e.event_name NOT LIKE '%Women%')) DESC
LIMIT 10;

-- 8.Are there any new events that have been introduced in recent editions of the Olympics?
SELECT event_name, sport_name, MIN(games_year) AS first_year
FROM sportsanalysis.consolidated_fact
GROUP BY event_name, sport_name
HAVING MIN(games_year) >= 2012
ORDER BY first_year DESC;

-- 9.Are there any events that have been discontinued or removed from the Olympics?
SELECT event_name, games_season, MAX(games_year) AS last_year
FROM sportsanalysis.consolidated_fact
GROUP BY event_name, games_season
HAVING MAX(games_year) < CASE WHEN games_season = 'Summer' THEN 2016 ELSE 2014 END
ORDER BY last_year DESC;

-- 10.Are there any notable trends in the height and weight of participants over time?
SELECT games_decade,
       ROUND(AVG(person_height), 1) AS avg_height_cm,
       ROUND(AVG(person_weight), 1) AS avg_weight_kg
FROM sportsanalysis.consolidated_fact
WHERE person_height > 0 AND person_weight > 0
GROUP BY games_decade
ORDER BY games_decade;

-- 11.Are there any dominant countries or regions in specific sports or events?
SELECT * FROM (
  SELECT sport_name, region_name, medals,
         ROUND(100.0 * medals / SUM(medals) OVER (PARTITION BY sport_name), 1) AS share_pct,
         SUM(medals) OVER (PARTITION BY sport_name) AS total,
         ROW_NUMBER() OVER (PARTITION BY sport_name ORDER BY medals DESC) AS rn
  FROM (SELECT sport_name, region_name, COUNT(*) AS medals
        FROM sportsanalysis.consolidated_fact
        WHERE medal_name <> 'NA'
        GROUP BY sport_name, region_name) t
) x
WHERE rn = 1 AND total >= 200
ORDER BY share_pct DESC;

-- 12.What factors contribute to the success or performance of participants from different countries?
SELECT CASE WHEN medal_name <> 'NA' THEN 'Medalist' ELSE 'Non-medalist' END AS grp,
       ROUND(AVG(games_competitor_age), 1) AS avg_age,
       ROUND(AVG(CASE WHEN person_height > 0 THEN person_height END), 1) AS avg_height,
       ROUND(AVG(CASE WHEN person_weight > 0 THEN person_weight END), 1) AS avg_weight
FROM sportsanalysis.consolidated_fact
GROUP BY 1;

-- 13.Are there any countries that consistently perform well in multiple Olympic editions?
SELECT region_name, COUNT(DISTINCT game_id) AS games_with_medals
FROM sportsanalysis.consolidated_fact
WHERE medal_name <> 'NA'
GROUP BY region_name
ORDER BY games_with_medals DESC
LIMIT 10;

-- 14.Are there any sports or events that have a higher number of medalists from a specific region?
SELECT * FROM (
  SELECT sport_name, region_name, medals,
         ROUND(100.0 * medals / SUM(medals) OVER (PARTITION BY sport_name), 1) AS share_pct,
         SUM(medals) OVER (PARTITION BY sport_name) AS total,
         ROW_NUMBER() OVER (PARTITION BY sport_name ORDER BY medals DESC) AS rn
  FROM (SELECT sport_name, region_name, COUNT(*) AS medals
        FROM sportsanalysis.consolidated_fact
        WHERE medal_name <> 'NA'
        GROUP BY sport_name, region_name) t
) x
WHERE rn = 1 AND total >= 200
ORDER BY share_pct DESC;

-- 15.What are some notable instances of unexpected or surprising medal wins?
SELECT region_name,
       COUNT(DISTINCT person_id) AS athletes,
       SUM(CASE WHEN medal_name = 'Gold' THEN 1 ELSE 0 END) AS golds
FROM sportsanalysis.consolidated_fact
GROUP BY region_name
HAVING SUM(CASE WHEN medal_name = 'Gold' THEN 1 ELSE 0 END) > 0
ORDER BY athletes ASC
LIMIT 10;

-- 16.Are there any regions that have experienced significant growth or decline in Olympic participation?
SELECT region_name,
       COUNT(DISTINCT CASE WHEN games_year = 1996 THEN person_id END) AS y1996,
       COUNT(DISTINCT CASE WHEN games_year = 2016 THEN person_id END) AS y2016,
       COUNT(DISTINCT CASE WHEN games_year = 2016 THEN person_id END)
     - COUNT(DISTINCT CASE WHEN games_year = 1996 THEN person_id END) AS change
FROM sportsanalysis.consolidated_fact
WHERE games_season = 'Summer'
GROUP BY region_name
ORDER BY change DESC;


SELECT 
    nr.region_name, 
    g.games_year, 
    COUNT(DISTINCT gc.person_id) AS participants 
FROM 
    sportsanalysis.competitor_event ce 
LEFT JOIN 
    sportsanalysis.medal m ON m.id = ce.medal_id 
JOIN 
    sportsanalysis.event e ON ce.event_id = e.id 
JOIN 
    sportsanalysis.sport s ON e.sport_id = s.id 
JOIN 
    sportsanalysis.games_competitor gc ON ce.competitor_id = gc.id 
JOIN 
    sportsanalysis.person_region pr ON gc.person_id = pr.person_id 
JOIN 
    sportsanalysis.noc_region nr ON pr.region_id = nr.id 
JOIN 
    sportsanalysis.games g ON gc.games_id = g.id 
GROUP BY 
    nr.region_name, 
    g.games_year
order by 
       nr.region_name, 
    g.games_year
-- 17.How do cultural or geographical factors influence the performance of regions in specific sports?
SELECT region_name,
       SUM(CASE WHEN games_season = 'Winter' THEN 1 ELSE 0 END) AS winter_medals,
       SUM(CASE WHEN games_season = 'Summer' THEN 1 ELSE 0 END) AS summer_medals
FROM sportsanalysis.consolidated_fact
WHERE medal_name <> 'NA'
GROUP BY region_name
ORDER BY winter_medals DESC;

-- 18.Are there any regions that have had a notable impact on the overall medal tally?
SELECT region_name,
       COUNT(*) AS total_medals,
       SUM(CASE WHEN medal_name = 'Gold' THEN 1 ELSE 0 END) AS gold,
	   SUM(CASE WHEN medal_name = 'Silver' THEN 1 ELSE 0 END) AS silver,
	   SUM(CASE WHEN medal_name = 'Bronze' THEN 1 ELSE 0 END) AS bronze
FROM sportsanalysis.consolidated_fact
WHERE medal_name <> 'NA'
GROUP BY region_name

























