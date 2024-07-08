-- SQL Project - Data Cleaning (File was converted from CSV to JSON to aid upload to MySQL Workbench)

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- Get data from original table
SELECT *
FROM world_layoffs.layoffs;

-- Create a staging table (copy of original table)
CREATE TABLE world_layoffs.layoffs_staging LIKE world_layoffs.layoffs;
INSERT INTO world_layoffs.layoffs_staging SELECT * FROM world_layoffs.layoffs;


-- 1. Remove Duplicates:
-- Check for duplicates (without modification)
SELECT *
FROM world_layoffs.layoffs_staging;

-- Identify duplicates using row_number()
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
       ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Show duplicates with row_num > 1 (without modification)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Create a temporary layoffs_staging2 table to store non-duplicates

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

-- Insert data with row_number() into layoffs_staging2
INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
       ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Verify empty layoffs_staging2 table (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Filter for duplicates in layoffs_staging2 (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Delete duplicates (rows where row_num > 1)
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Verify after deleting duplicates (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2;

-- **Note:** We cannot delete from a CTE (Common Table Expression) as it's temporary. So, we create a new table and delete duplicates there. 


-- 2. Standardize Data: 
-- Check for leading/trailing whitespace (no changes)
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

-- Remove whitespace from the 'company' column
UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

-- Find null or empty industry values
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Check industry values for 'Crypto%' (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Check industry values for 'Bally%' (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

-- Check industry values for 'airbnb%' (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Since 'airbnb' has a populated industry in other rows, update null values in 'airbnb' to the industry of another row with the same company name
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Verify if null industry values are fixed (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Standardize 'Crypto Currency' variations to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Verify standardized industry values (no changes)
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Standardize trailing periods in 'country'
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

-- Remove trailing periods from 'country'
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify standardized country values (no changes)
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Check location data (no changes)
SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

-- Convert 'date' format using STR_TO_DATE
SELECT *,
       STR_TO_DATE(`date`, '%m/%d/%Y') AS formatted_date
FROM world_layoffs.layoffs_staging2;

-- Update 'date' column to a proper date format
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Handle 'NONE' values in 'date' (optional)
-- UPDATE world_layoffs.layoffs_staging2
-- SET `date` =
--   CASE
--     WHEN `date` IS NOT NULL AND `date` != 'NONE' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
--     ELSE NULL
--   END;

-- Verify 'date' format after update (no changes)
SELECT `date`
FROM world_layoffs.layoffs_staging2;

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Convert 'funds_raised_millions' to a numeric data type (optional)
-- ALTER TABLE layoffs_staging2
-- MODIFY COLUMN `funds_raised_millions` INT;

-- Check data types after conversion (optional,)
-- SELECT CASE WHEN funds_raised_millions IS NOT NULL AND funds_raised_millions != 'NONE' THEN CAST(funds_raised_millions AS SIGNED INTEGER)
--          ELSE NULL
--        END AS converted_int
-- FROM world_layoffs.layoffs_staging2;
    
    
-- 3.  Remove Unnecessary Columns and Rows
-- Find rows with 'NONE' in total_laid_off (or comment out and use the next query for null checks)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off = 'NONE';

-- Find rows with null values in both total_laid_off and percentage_laid_off (if preferred)
-- SELECT *
-- FROM world_layoffs.layoffs_staging2
-- WHERE total_laid_off IS NULL
-- AND percentage_laid_off IS NULL;

-- Find rows with 'NONE' or empty industry values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry = 'NONE' OR Industry = '';

-- Find rows with company 'Airbnb' (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb';

-- Update empty industry values in 'company' based on another row with the same company (if one exists)
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IN ('', 'NONE')) AND t2.industry NOT IN ('NONE');

-- Set empty industry values to null
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Verify if industry null values are handled (no changes)
SELECT t1.industry, t2.industry
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2 ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry NOT IN ('NONE');

-- Update remaining null industry values from another row with the same company
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Check for remaining 'Bally' company issues (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

-- Update 'NONE' values in other columns to null
UPDATE world_layoffs.layoffs_staging2
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'None';

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

-- Verify null values after update (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Find rows with null values in both total_laid_off and percentage_laid_off (optional, uncomment if needed)
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Verify after potentially deleting rows (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Drop the temporary row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Verify final table structure (no changes)
SELECT *
FROM world_layoffs.layoffs_staging2;



























