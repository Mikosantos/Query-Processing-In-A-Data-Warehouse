-- QUERY 1
SELECT 
    MONTH(g.Release_date) AS release_month,
    COUNT(fs.fact_id) AS total_games,
    AVG(fs.ave_playtime_forever) AS avg_playtime,
    SUM(fs.positive_count) AS total_positive_reviews,
    SUM(fs.negative_count) AS total_negative_reviews
FROM FACT_STREAM fs JOIN DIM_GAME g ON fs.AppID = g.AppID
WHERE YEAR(g.Release_date) = 2020
GROUP BY release_month
ORDER BY release_month ASC;


-- QUERY 2
SELECT g.Name, g.Release_date, f.metacritic_score, Estimated_owners, d.genreName
FROM FACT_STREAM f 	JOIN DIM_GAME g				ON f.AppID = g.AppID
					JOIN BRIDGE_GAME_GENRE bg 	ON g.AppID = bg.AppID
					JOIN DIM_GENRE d 			ON bg.genreID = d.genreID
WHERE f.metacritic_score > 50 	AND d.genreName = 'Indie'
								AND f.Estimated_owners = ('20000 - 50000');
                                
-- QUERY 3
SELECT dev.devname,
       genre.genrename,
       AVG(fs.positive_count)
FROM   FACT_STREAM AS fs       
       JOIN BRIDGE_GAME_GENRE AS bgg
         ON fs.appid = bgg.appid
       JOIN DIM_GENRE AS genre
         ON bgg.genreid = genre.genreid
       JOIN BRIDGE_GAME_DEVELOPER AS bgd
         ON fs.appid = bgd.appid
       JOIN DIM_DEVELOPER AS dev
         ON bgd.devid = dev.devid
GROUP  BY dev.devname,
          genre.genrename
HAVING AVG(fs.positive_count) > 50000
       AND genre.genrename = 'Indie'
ORDER  BY AVG(fs.positive_count) DESC,
          dev.devname,
          genre.genrename;   

-- QUERY 4
SELECT 
    G.Name, 
    GR.genreName,
    (CAST(SUBSTRING_INDEX(F.Estimated_owners,'-', 1) 
    AS SIGNED) + CAST(SUBSTRING_INDEX( 
    F.Estimated_owners,'-', -1) AS SIGNED))/2
    AS owners_average

FROM FACT_STREAM F 
JOIN DIM_GAME G ON F.AppID = G.AppID
JOIN BRIDGE_GAME_GENRE BG ON BG.AppID= G.AppID
JOIN DIM_GENRE GR ON GR.genreID = BG.genreID
WHERE GR.genreName = 'Action'
ORDER BY owners_average DESC, G.Name
LIMIT 100;

-- WITH INDEX (OPTIMIZED)
-- QUERY 1
CREATE INDEX idx_release_date ON DIM_GAME(Release_date); 
CREATE INDEX idx_fact_stream_appid ON FACT_STREAM(AppID); 
CREATE INDEX idx_dim_game_appid ON DIM_GAME(AppID);

SELECT 
    MONTH(g.Release_date) AS release_month,
    COUNT(fs.fact_id) AS total_games,
    AVG(fs.ave_playtime_forever) AS avg_playtime,
    SUM(fs.positive_count) AS total_positive_reviews,
    SUM(fs.negative_count) AS total_negative_reviews
FROM FACT_STREAM fs JOIN DIM_GAME g ON fs.AppID = g.AppID
WHERE YEAR(g.Release_date) = 2020
GROUP BY release_month
ORDER BY release_month ASC;

-- QUERY 2
CREATE INDEX idx_factstream_metacritic_score ON  FACT_STREAM(metacritic_score);
CREATE INDEX idx_factstream_estimated_owners ON FACT_STREAM(Estimated_owners);
CREATE INDEX idx_dimgenre_genrename ON DIM_GENRE(genreName);

SELECT g.Name,
       g.Release_date,
       f.metacritic_score,
       f.Estimated_owners,
       d.genreName
FROM   FACT_STREAM f JOIN DIM_GAME g ON f.AppID = g.AppID
          JOIN BRIDGE_GAME_GENRE bg ON g.AppID = bg.AppID
          JOIN DIM_GENRE d ON bg.genreID = d.genreID
WHERE f.metacritic_score > 50 AND d.genreName = 'Indie'
            AND f.Estimated_owners IN ('50000 - 100000'); 
            
-- QUERY 3
CREATE INDEX idx_bgg_genreID ON BRIDGE_GAME_GENRE(genreID); 

SELECT dev.devname,
       genre.genrename,
       AVG(sub_fs.positive_count) AS dev_genre_avg
FROM   (SELECT fs.appID,
               fs.positive_count,
               bgg.genreID,
               bgd.devID
        FROM   FACT_STREAM AS fs
				JOIN BRIDGE_GAME_GENRE AS bgg ON fs.appID = bgg.appID
				JOIN BRIDGE_GAME_DEVELOPER AS bgd ON fs.appID = bgd.appID) AS sub_fs
				JOIN DIM_GENRE AS genre ON sub_fs.genreID = genre.genreID
				JOIN DIM_DEVELOPER AS dev ON sub_fs.devID = dev.devID
WHERE  genre.genrename = 'Indie'
GROUP  BY dev.devname,
          genre.genrename
HAVING dev_genre_avg > 50000
ORDER  BY dev_genre_avg DESC,
          dev.devname,
          genre.genrename;
          
-- QUERY 4
CREATE INDEX idx_genre ON DIM_GENRE(genreName);
CREATE INDEX idx_game ON DIM_GAME(AppID);
CREATE INDEX idx_fact_stream ON FACT_STREAM(AppID);

SELECT 
    G.Name, 
    GR.genreName,
    (CAST(SUBSTRING_INDEX(F.Estimated_owners,'-', 1) 
    AS SIGNED) + CAST(SUBSTRING_INDEX( 
    F.Estimated_owners,'-', -1) AS SIGNED))/2
    AS owners_average
FROM FACT_STREAM F 
JOIN DIM_GAME G ON F.AppID = G.AppID
JOIN BRIDGE_GAME_GENRE BG ON BG.AppID= G.AppID
JOIN DIM_GENRE GR ON GR.genreID = BG.genreID
WHERE GR.genreName = 'Action'
ORDER BY owners_average DESC, G.Name
LIMIT 100;


