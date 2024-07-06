-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022



SELECT * 
FROM world_layoffs.layoffs;



-- Create a staging table. A proxy table which we will work on and clean the data. Initial table with the raw data will be left intact in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * 
FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First duplicates in the table


SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;


-- Using CTE to identify duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
    )
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- To confirm if duplicate result shown is correct on table

SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Casper';

-- 'Delete' cannot work on CTE, as CTE cannot be updated. 'DELETE' statement is like an update statement 
-- DELETE
-- FROM duplicate_CTE
-- WHERE row_num > 1 

-- To enusre we remove intended duplicate from table we have to put the subquery into a new table in the database
-- Create another table with extra row and deleting it where staging 2 =2

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- We get an empty table
SELECT *
FROM world_layoffs.layoffs_staging2
;

INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
;

-- Table updated
SELECT *
FROM world_layoffs.layoffs_staging2;

-- To filter for duplicate
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Delete rows were row_num is greater than 2
DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Recall table
SELECT *
FROM world_layoffs.layoffs_staging2;

-- PS We had to go through this procedure as we do not have a unique column on table




-- 2. Standardizing Data (Finding issues with data and fixing it)

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- To take white space off the ends we use TRIM
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

-- if we look at industry it looks like we have some null and empty rows
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- let's take a look at these
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'Crypto%';
-- nothing wrong here

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

-- nothing wrong here
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

-- now if we check those are all null

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- now that's taken care of:
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- --------------------------------------------------
-- we also need to look at 

SELECT *
FROM world_layoffs.layoffs_staging2;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

SELECT *
FROM world_layoffs.layoffs_staging2;
-- ----------------------------------------------------------------------------
-- Location 

SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

-- Let's also fix the date columns:
SELECT *
FROM world_layoffs.layoffs_staging2;

-- we can use str to date to update this field
SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

-- UPDATE world_layoffs.layoffs_staging2
-- SET `date` = CASE WHEN `date` IS NULL THEN NULL  -- Set NULL for None values
--                           WHEN `date` IS NOT NULL THEN STR_TO_DATE(`date`, '%m/%d/%Y')
--                           END;
                          
UPDATE world_layoffs.layoffs_staging2
SET `date` = 
    CASE
        WHEN `date` IS NOT NULL AND `date` != 'NONE' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
        ELSE NULL  
    END;      
    
SELECT `date`
FROM world_layoffs.layoffs_staging2;   

SELECT funds_raised_millions
FROM world_layoffs.layoffs_staging2;  

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

##UPDATE world_layoffs.layoffs_staging2
-- SET funds_raised_millions =  
          
--              CASE 
--                  WHEN funds_raised_millions IS NOT NULL AND funds_raised_millions != 'NONE' THEN CAST(funds_raised_millions AS SIGNED INTEGER)
--              WHEN funds_raised_millions IS NULL THEN NULL
--              ELSE 0
--         END;
     

-- SELECT CASE WHEN funds_raised_millions IS NOT NULL AND funds_raised_millions != 'NONE' THEN CAST(funds_raised_millions AS SIGNED INTEGER)
--              ELSE NULL
--         END AS converted_int
-- FROM world_layoffs.layoffs_staging2;

-- ALTER TABLE world_layoffs.layoffs_staging2
-- MODIFY COLUMN funds_raised_millions INT; 

SELECT *
FROM world_layoffs.layoffs_staging2;



-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values






-- 4. remove any columns and rows we need to

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off = 'NONE' ;

-- SELECT *
-- FROM world_layoffs.layoffs_staging2
-- WHERE total_laid_off IS NULL
-- AND percentage_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off = 'NONE' 
AND percentage_laid_off = 'NONE';


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry = 'NONE' 
OR Industry = '' ;
-- WHERE Industry NOT IN ('', 'NONE');

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb' ;

SELECT *
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IN ('', 'NONE'))
AND t2.industry NOT IN ('NONE');

UPDATE world_layoffs.layoffs_staging2 
SET industry = NULL
WHERE industry = '' ;

SELECT t1.industry, t2.industry
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IN ('', 'NONE'))
AND t2.industry NOT IN ('NONE');

UPDATE world_layoffs.layoffs_staging2 
SET industry = NULL
WHERE industry = '' ;

SELECT t1.industry, t2.industry
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry NOT IN ('NONE');

UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Seems we still have troubles with bally
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%' ;

SELECT *
FROM world_layoffs.layoffs_staging2;

-- Updating all from NONE to NULL
UPDATE world_layoffs.layoffs_staging2 
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'None' ;

UPDATE world_layoffs.layoffs_staging2 
SET total_laid_off = NULL
WHERE total_laid_off = 'None';

UPDATE world_layoffs.layoffs_staging2 
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'None';

UPDATE world_layoffs.layoffs_staging2 
SET stage = NULL
WHERE stage = 'None';

UPDATE world_layoffs.layoffs_staging2 
SET industry = NULL
WHERE industry = 'None';

SELECT *
FROM world_layoffs.layoffs_staging2;


-- Delete Useless data we can't really use

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;


































