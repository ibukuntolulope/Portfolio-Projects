
select * from artist; -- 421 -json
select * from canvas_size; -- 200 -json
select * from image_link; -- 14,775 - csv
select * from museum_hours; -- 351 - csv
select * from museum; -- 57 - json
select * from product_size; -- 110,347 - JSON
select * from subject; -- 6771 - CSV
select * from work; -- 14776- JSON


select *
from  product_size;

SELECT CASE WHEN funds_raised_millions IS NOT NULL THEN CAST(funds_raised_millions AS SIGNED INTEGER)
   ELSE NULL
      END AS converted_int
FROM world_layoffs.layoffs_staging2;

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN funds_raised_millions INT;

UPDATE painting.work
SET museum_id = NULL
WHERE museum_id = 'None';

UPDATE painting.work
SET museum_id = NULL
WHERE TRIM(museum_id) = '';

UPDATE painting.museum
SET postal = NULL
WHERE LENGTH(postal) = 0;

UPDATE painting.work
SET style = NULL
WHERE LENGTH(style) = 0;

-- 1) Fetch all the paintings which are not displayed on any museums?
	select * from work where museum_id is null;


-- 2) Are there museuems without any paintings?
	SELECT *
FROM museum m
Right JOIN work w 
ON m.museum_id = w.museum_id
WHERE w.work_id IS NULL; 


-- 3) How many paintings have an regular price of more than their regular price asking price? 
	select * from product_size
	where sale_price < regular_price;


-- 4) Identify the paintings whose asking price is less than 50% of its regular price
	select * 
	from product_size
	where sale_price < (regular_price*0.5);


-- 5) Which canva size costs the most?
SELECT canvas_size.size_id, product_size.sale_price AS Sales
FROM canvas_size 
JOIN product_size ON canvas_size.size_id =  product_size.size_id
ORDER BY Sales DESC
LIMIT 1;
;
				
-- 6) Delete duplicate records from work, product_size, subject and image_link tables
SELECT *
FROM work;

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
FROM work;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
FROM work
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM work
WHERE work_id = 122691;

DELETE work
FROM work
JOIN (
  SELECT *, ROW_NUMBER() OVER (
PARTITION BY work_id, name, artist_id, style, museum_id) AS row_num
FROM work
) duplicate_cte ON work.work_id = duplicate_cte.work_id 
WHERE duplicate_cte.row_num > 1;

#Duplicates in product size
SELECT *
FROM product_size;

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
FROM product_size;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
FROM product_size
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM product_size
WHERE work_id = 23448;

DELETE product_size
FROM product_size
JOIN (
  SELECT *, ROW_NUMBER() OVER (
PARTITION BY work_id, size_id, sale_price, regular_price) AS row_num
FROM product_size
) duplicate_cte ON product_size.work_id = duplicate_cte.work_id 
WHERE duplicate_cte.row_num > 1;

#Duplicates in subject
SELECT *
FROM subject;

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, subject) AS row_num
FROM subject;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, subject) AS row_num
FROM subject
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM subject
WHERE work_id = 181318;

DELETE subject
FROM subject
JOIN (
  SELECT *, ROW_NUMBER() OVER (
PARTITION BY work_id, subject) AS row_num
FROM subject
) duplicate_cte ON subject.work_id = duplicate_cte.work_id 
WHERE duplicate_cte.row_num > 1;

#Duplicates in image_link
SELECT *
FROM image_link;

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
FROM image_link;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
FROM image_link
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM image_link
WHERE work_id = 181318;

DELETE image_link
FROM image_link
JOIN (
  SELECT *, ROW_NUMBER() OVER (
PARTITION BY work_id, url, thumbnail_small_url, thumbnail_large_url) AS row_num
FROM image_link
) duplicate_cte ON image_link.work_id = duplicate_cte.work_id 
WHERE duplicate_cte.row_num > 1;

-- 7) Identify the museums with invalid city information in the given dataset
SELECT *
FROM museum
WHERE city REGEXP '^[0-9]'; -- Matches cities that lack any letters

-- 8) Museum_Hours table has 1 invalid entry. Identify it.
SELECT *
FROM museum_hours;

SELECT *
FROM museum_hours
WHERE 
    day NOT IN ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
    OR open REGEXP '^[0-1]?[0-9]:[0-5][0-9]:[0-5][0-9]$'  
    OR close REGEXP '^[0-1]?[0-9]:[0-5][0-9]:[0-5][0-9]$';

-- 9) Fetch the top 10 most famous painting subject
	SELECT * 
	FROM (
		SELECT s.subject,count(1) as no_of_paintings,
        RANK() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;


-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
	select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');

-- 11) How many museums are open every single day?
select museum_id, count(*) -- count (1) 
		  from museum_hours
		  group by museum_id
		  having count(*) = 7;
          
	select count(*) -- count (1)
	from (select museum_id, count(*) -- count (1) 
		  from museum_hours
		  group by museum_id
		  having count(*) = 7) AS Every_day;


-- 12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
	select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;


-- 13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;


-- 14) Display the 3 least popular canva sizes
	SELECT label, ranking, no_of_paintings
FROM (
    SELECT cs.size_id, cs.label, COUNT(1) AS no_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(1)) AS ranking
    FROM work w
    JOIN product_size ps ON ps.work_id = w.work_id
    JOIN canvas_size cs ON cs.size_id = ps.size_id
    GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;

-- 15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
	SELECT museum_name, city, day, open, close, duration
FROM (
    SELECT 
        m.name AS museum_name, 
        m.state AS city, 
        day, 
        open, 
        close,
        STR_TO_DATE(open, '%h:%i %p') AS opening_time,   
        STR_TO_DATE(close, '%h:%i %p') AS closing_time,
        TIMEDIFF(STR_TO_DATE(close, '%h:%i %p'), STR_TO_DATE(open, '%h:%i %p')) AS duration,
        RANK() OVER (ORDER BY TIMEDIFF(STR_TO_DATE(close, '%h:%i %p'), STR_TO_DATE(open, '%h:%i %p')) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
) x
WHERE x.rnk = 1;

-- 16) Which museum has the most no of most popular painting style?
	with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


-- 17) Identify the artists whose paintings are displayed in multiple countries
	with cte as
		(select distinct a.full_name as artist
        , w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;


-- 18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
	WITH cte_country AS (
    SELECT country, COUNT(1) AS country_count, 
           RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rnk
    FROM museum
    GROUP BY country
),
cte_city AS (
    SELECT city, COUNT(1) AS city_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rnk
    FROM museum
    GROUP BY city
)

SELECT 
    GROUP_CONCAT(DISTINCT CASE WHEN country_rnk = 1 THEN country END SEPARATOR ', ') AS countries,
    GROUP_CONCAT(DISTINCT CASE WHEN city_rnk = 1 THEN city END SEPARATOR ', ') AS cities
FROM cte_country
CROSS JOIN cte_city;



-- 19) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
	WITH cte AS (
    SELECT *
        , RANK() OVER (ORDER BY sale_price DESC) AS rnk
        , RANK() OVER (ORDER BY sale_price) AS rnk_asc
    FROM product_size
)
SELECT w.name AS painting, 
       cte.sale_price,
       a.full_name AS artist,
       m.name AS museum, m.city,
       cz.label AS canvas
FROM cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON cz.size_id = cte.size_id 
WHERE rnk = 1 OR rnk_asc = 1; 

-- 20) Which country has the 5th highest no of paintings?
	with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;


-- 21) Which are the 3 most popular and 3 least popular painting styles?
	with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;


-- 22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	




