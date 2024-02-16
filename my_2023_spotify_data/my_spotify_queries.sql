USE my_spotify_data;

-- 1. Prepare and Clean Dataset --

# merge two streaming history datasets
CREATE TABLE IF NOT EXISTS stream_history AS
(SELECT * FROM my_spotify_data.streaminghistory0
UNION ALL 
SELECT * FROM my_spotify_data.streaminghistory1);

# Change column name 
ALTER TABLE stream_history
RENAME COLUMN endTime TO playTime;

# Create new columns for month and hour played 
ALTER TABLE stream_history
ADD COLUMN month_played varchar(10) AS (MONTHNAME(playTime));

ALTER TABLE stream_history
ADD COLUMN hour_played INT AS (HOUR(playTime));

-- 2. SQL Queries --

# 1. What is the earliest and latest listening dates?
SELECT MIN(playTime) AS first_date, MAX(playTime) AS last_date
FROM stream_history;

# 2. What are my top 10 most listend to songs of 2023? 
SELECT trackName, artistName, SUM(msPlayed)/60000 AS minPlayed, COUNT(trackName) as timesPlayed
FROM stream_history
GROUP BY trackName, artistName 
ORDER BY minPlayed DESC
LIMIT 10;

# 3. What are my top 10 most listened to artists of 2023?
SELECT artistName, SUM(msPlayed) / 60000 AS minPlayed
FROM stream_history
GROUP BY artistName
ORDER BY minPlayed DESC
LIMIT 10;

# 4. What are my top 3 songs from my top most listened to artists?

# 5. How many minutes did I listen to music each month?
SELECT MONTHNAME(playTime) AS months, SUM(msPlayed) / 60000 AS minPlayed
FROM stream_history
GROUP BY months
ORDER BY minPlayed DESC;

# 6. What are my listening habits for each hour of the day?
SELECT hour_played, SUM(msPlayed)/60000 AS minPlayed
FROM stream_history
GROUP BY hour_played
ORDER BY hour_played ASC;

# 7. What time of day did I listen to music the most?
SELECT hour_played, SUM(msPlayed)/60000 AS minPlayed
FROM stream_history
GROUP BY hour_played
ORDER BY minPlayed DESC;

# 8. Who are my top 5 artists each month and how many minutes did I listen to each artist?
WITH bymonth AS (
	SELECT month_played, artistName, SUM(msPlayed)/60000 AS minPlayed
	FROM stream_history
	GROUP BY month_played, artistName
),
ranked AS (
	SELECT *, RANK() OVER(PARTITION BY month_played ORDER BY minPlayed DESC) AS num
    FROM bymonth
)
SELECT month_played, artistName, minPlayed 
FROM ranked 
WHERE num <= 5
ORDER BY month_played;
