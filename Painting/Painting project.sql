-- Initial data overview (result counts and intended output formats)
SELECT * FROM artist; -- 421 artists - output as JSON
SELECT * FROM canvas_size; -- 200 canvas sizes - output as JSON
SELECT * FROM image_link; -- 14,775 image links - output as CSV
SELECT * FROM museum_hours; -- 351 museum hour entries - output as CSV
SELECT * FROM museum; -- 57 museums - output as JSON
SELECT * FROM product_size; -- 110,347 product size entries - output as JSON
SELECT * FROM subject; -- 6,771 subjects - output as CSV
SELECT * FROM work; -- 14,776 artworks - output as JSON


-- Examine product size data
SELECT * FROM product_size;


-- Data cleaning and preparation 
UPDATE painting.work
SET museum_id = NULL
WHERE museum_id = 'None'; -- Set museum_id to NULL where it's 'None'

UPDATE painting.work
SET museum_id = NULL
WHERE TRIM(museum_id) = ''; -- Set museum_id to NULL where it's an empty string after trimming

UPDATE painting.museum
SET postal = NULL
WHERE LENGTH(postal) = 0; -- Set postal to NULL where it's an empty string

UPDATE painting.work
SET style = NULL
WHERE LENGTH(style) = 0; -- Set style to NULL where it's an empty string


-- 1) Fetch all the paintings which are not displayed on any museums
SELECT * 
FROM work 
WHERE museum_id IS NULL;


-- 2) Are there museums without any paintings?
SELECT *
FROM museum m
RIGHT JOIN work w 
ON m.museum_id = w.museum_id
WHERE w.work_id IS NULL;


-- 3) How many paintings have a regular price more than their sale price? 
SELECT * 
FROM product_size
WHERE sale_price < regular_price;


-- 4) Identify the paintings whose asking price is less than 50% of its regular price
SELECT * 
FROM product_size
WHERE sale_price < (regular_price * 0.5);


-- 5) Which canvas size costs the most?
SELECT canvas_size.size_id, MAX(product_size.sale_price) AS highest_sales_price
FROM canvas_size
JOIN product_size ON canvas_size.size_id = product_size.size_id
GROUP BY canvas_size.size_id
ORDER BY highest_sales_price DESC
LIMIT 1;


-- 6) Delete duplicate records from work, product_size, subject, and image_link tables
-- ... (series of SELECT, WITH, and DELETE statements to identify and remove duplicates)

WITH work_duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
    FROM work
), product_size_duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
    FROM product_size
), subject_duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY work_id, subject) AS row_num
    FROM subject
), image_link_duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
    FROM image_link
)
DELETE FROM work 
WHERE work_id IN (SELECT work_id FROM work_duplicates WHERE row_num > 1);

DELETE FROM product_size
WHERE work_id IN (SELECT work_id FROM product_size_duplicates WHERE row_num > 1);

DELETE FROM subject
WHERE work_id IN (SELECT work_id FROM subject_duplicates WHERE row_num > 1);

DELETE FROM image_link
WHERE work_id IN (SELECT work_id FROM image_link_duplicates WHERE row_num > 1);

-- SELECT *
-- FROM work;

-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
-- FROM work;

-- WITH duplicate_cte AS
-- (
-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
-- FROM work
-- )
-- SELECT *
-- FROM duplicate_cte
-- WHERE row_num > 1;

-- SELECT *
-- FROM work
-- WHERE work_id = 122691;

-- DELETE work
-- FROM work
-- JOIN (
--   SELECT *, ROW_NUMBER() OVER (
-- PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
-- FROM work
-- ) duplicate_cte ON work.work_id = duplicate_cte.work_id 
-- WHERE duplicate_cte.row_num > 1;

-- #Duplicates in product size
-- SELECT *
-- FROM product_size;

-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
-- FROM product_size;

-- WITH duplicate_cte AS
-- (
-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
-- FROM product_size
-- )
-- SELECT *
-- FROM duplicate_cte
-- WHERE row_num > 1;

-- SELECT *
-- FROM product_size
-- WHERE work_id = 23448;

-- DELETE product_size
-- FROM product_size
-- JOIN (
--   SELECT *, ROW_NUMBER() OVER (
-- PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
-- FROM product_size
-- ) duplicate_cte ON product_size.work_id = duplicate_cte.work_id 
-- WHERE duplicate_cte.row_num > 1;

-- #Duplicates in subject
-- SELECT *
-- FROM subject;

-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, subject) AS row_num
-- FROM subject;

-- WITH duplicate_cte AS
-- (
-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, subject) AS row_num
-- FROM subject
-- )
-- SELECT *
-- FROM duplicate_cte
-- WHERE row_num > 1;

-- SELECT *
-- FROM subject
-- WHERE work_id = 181318;

-- DELETE subject
-- FROM subject
-- JOIN (
--   SELECT *, ROW_NUMBER() OVER (
-- PARTITION BY work_id, subject) AS row_num
-- FROM subject
-- ) duplicate_cte ON subject.work_id = duplicate_cte.work_id 
-- WHERE duplicate_cte.row_num > 1;

-- #Duplicates in image_link
-- SELECT *
-- FROM image_link;

-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
-- FROM image_link;

-- WITH duplicate_cte AS
-- (
-- SELECT *,
-- ROW_NUMBER() OVER (
-- PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
-- FROM image_link
-- )
-- SELECT *
-- FROM duplicate_cte
-- WHERE row_num > 1;

-- SELECT *
-- FROM image_link
-- WHERE work_id = 181318;

-- DELETE image_link
-- FROM image_link
-- JOIN (
--   SELECT *, ROW_NUMBER() OVER (
-- PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
-- FROM image_link
-- ) duplicate_cte ON image_link.work_id = duplicate_cte.work_id 
-- WHERE duplicate_cte.row_num > 1;

-- 7) Identify museums with invalid city information (cities containing only numbers)
SELECT *
FROM museum
WHERE city REGEXP '^[0-9]'; 


-- 8) Find the invalid entry in museum_hours (invalid day or time format)
SELECT *
FROM museum_hours
WHERE
   day NOT IN ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
   OR open NOT REGEXP '^[0-1]?[0-9]:[0-5][0-9] [AP]M$' 
   OR close NOT REGEXP '^[0-1]?[0-9]:[0-5][0-9] [AP]M$';

-- 9) Fetch the top 10 most frequent painting subjects (with ranking)
SELECT subject, no_of_paintings
FROM (
    SELECT s.subject, COUNT(*) AS no_of_paintings,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM work w
    JOIN subject s ON s.work_id = w.work_id
    GROUP BY s.subject
) x
WHERE ranking <= 10;

-- 10) Identify museums open on both Sunday and Monday
SELECT DISTINCT m.name AS museum_name, m.city, m.state, m.country
FROM museum_hours mh
JOIN museum m ON m.museum_id = mh.museum_id
WHERE day = 'Sunday'
  AND EXISTS (
    SELECT 1 FROM museum_hours mh2
    WHERE mh2.museum_id = mh.museum_id
      AND mh2.day = 'Monday'
);


-- 11) How many museums are open every single day?
SELECT COUNT(*) AS museums_open_every_day
FROM (
  SELECT museum_id, COUNT(*) AS days_open
  FROM museum_hours
  GROUP BY museum_id
  HAVING days_open = 7
) AS museums_open_all_week;


-- 12) Which are the top 5 most popular museums? (By number of paintings)
SELECT m.name AS museum, m.city, m.country, x.no_of_paintings
FROM (
  SELECT m.museum_id, COUNT(*) AS no_of_paintings,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work w
  JOIN museum m ON m.museum_id = w.museum_id
  GROUP BY m.museum_id
) x
JOIN museum m ON m.museum_id = x.museum_id
WHERE x.rnk <= 5;


-- 13) Who are the top 5 most popular artists? (By number of paintings)
SELECT a.full_name AS artist, a.nationality, x.no_of_paintings
FROM (
  SELECT a.artist_id, COUNT(*) AS no_of_paintings,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work w
  JOIN artist a ON a.artist_id = w.artist_id
  GROUP BY a.artist_id
) x
JOIN artist a ON a.artist_id = x.artist_id
WHERE x.rnk <= 5;


-- 14) Display the 3 least popular canvas sizes
SELECT label, ranking, no_of_paintings
FROM (
  SELECT cs.size_id, cs.label, COUNT(*) AS no_of_paintings,
         DENSE_RANK() OVER (ORDER BY COUNT(*)) AS ranking
  FROM work w
  JOIN product_size ps ON ps.work_id = w.work_id
  JOIN canvas_size cs ON cs.size_id = ps.size_id
  GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;


-- 15) Which museum is open for the longest duration in a day?
SELECT museum_name, city, day, open, close, duration
FROM (
  SELECT 
    m.name AS museum_name,
    m.state AS city,
    day,
    open,
    close,
    TIMEDIFF(STR_TO_DATE(close, '%h:%i %p'), STR_TO_DATE(open, '%h:%i %p')) AS duration,
    RANK() OVER (ORDER BY TIMEDIFF(STR_TO_DATE(close, '%h:%i %p'), STR_TO_DATE(open, '%h:%i %p')) DESC) AS rnk
  FROM museum_hours mh
  JOIN museum m ON m.museum_id = mh.museum_id
) x
WHERE x.rnk = 1;


-- 16) Which museum has the most paintings of the most popular style?
WITH pop_style AS (
  SELECT style, RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work
  GROUP BY style
),
cte AS (
  SELECT w.museum_id, m.name AS museum_name, ps.style, COUNT(*) AS no_of_paintings,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work w
  JOIN museum m ON m.museum_id = w.museum_id
  JOIN pop_style ps ON ps.style = w.style
  WHERE w.museum_id IS NOT NULL
    AND ps.rnk = 1
  GROUP BY w.museum_id, m.name, ps.style
)
SELECT museum_name, style, no_of_paintings
FROM cte
WHERE rnk = 1;

-- 17) Identify artists whose paintings are displayed in multiple countries
WITH cte AS (
  SELECT DISTINCT a.full_name AS artist, w.name AS painting, m.name AS museum, m.country
  FROM work w
  JOIN artist a ON a.artist_id = w.artist_id
  JOIN museum m ON m.museum_id = w.museum_id
)
SELECT artist, COUNT(*) AS no_of_countries
FROM cte
GROUP BY artist
HAVING COUNT(*) > 1
ORDER BY no_of_countries DESC;


-- 18) Display the country and city with the most museums (comma-separated if multiple)
WITH cte_country AS (
  SELECT country, COUNT(*) AS country_count,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS country_rnk
  FROM museum
  GROUP BY country
),
cte_city AS (
  SELECT city, COUNT(*) AS city_count,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS city_rnk
  FROM museum
  GROUP BY city
)
SELECT 
  GROUP_CONCAT(DISTINCT CASE WHEN country_rnk = 1 THEN country END SEPARATOR ', ') AS countries,
  GROUP_CONCAT(DISTINCT CASE WHEN city_rnk = 1 THEN city END SEPARATOR ', ') AS cities
FROM cte_country
CROSS JOIN cte_city;


-- 19) Identify the artist and museum for the most/least expensive paintings
WITH cte AS (
  SELECT *, RANK() OVER (ORDER BY sale_price DESC) AS rnk,
             RANK() OVER (ORDER BY sale_price) AS rnk_asc
  FROM product_size
)
SELECT w.name AS painting, cte.sale_price,
       a.full_name AS artist,
       m.name AS museum, m.city,
       cz.label AS canvas
FROM cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON cz.size_id = cte.size_id 
WHERE rnk = 1 OR rnk_asc = 1; 


-- 20) Which country has the 5th highest number of paintings?
WITH cte AS (
  SELECT m.country, COUNT(*) AS no_of_paintings,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work w
  JOIN museum m ON m.museum_id = w.museum_id
  GROUP BY m.country
)
SELECT country, no_of_paintings
FROM cte
WHERE rnk = 5;


-- 21) Which are the 3 most and 3 least popular painting styles?
WITH cte AS (
  SELECT style, COUNT(*) AS cnt,
         RANK() OVER (ORDER BY COUNT(*) DESC) rnk,
         COUNT(*) OVER () AS no_of_records
  FROM work
  WHERE style IS NOT NULL
  GROUP BY style
)
SELECT style, 
       CASE WHEN rnk <= 3 THEN 'Most Popular' ELSE 'Least Popular' END AS remarks
FROM cte
WHERE rnk <= 3 OR rnk > no_of_records - 3;


-- 22) Which artist has the most portraits outside the USA?
SELECT full_name AS artist_name, nationality, no_of_paintings
FROM (
  SELECT a.full_name, a.nationality, COUNT(*) AS no_of_paintings,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM work w
  JOIN artist a ON a.artist_id = w.artist_id
  JOIN subject s ON s.work_id = w.work_id
  JOIN museum m ON m.museum_id = w.museum_id
  WHERE s.subject = 'Portraits'
    AND m.country != 'USA'
  GROUP BY a.full_name, a.nationality
) x
WHERE rnk = 1; 
