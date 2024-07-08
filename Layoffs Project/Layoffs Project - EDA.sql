-- Exploratory Data Analysis

-- This script performs exploratory data analysis (EDA) on the world_layoffs.layoffs_staging2 table.

-- Get an overview of the data
SELECT *
FROM world_layoffs.layoffs_staging2;

**Extracting Useful Values:**

-- Find the maximum total laid off value
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Convert 'funds_raised_millions' to a numeric data type (if necessary)
-- This ensures proper calculations involving this column.
SELECT CASE WHEN funds_raised_millions IS NOT NULL THEN CAST(funds_raised_millions AS SIGNED INTEGER)
             ELSE NULL
        END AS converted_int
FROM world_layoffs.layoffs_staging2;

-- Update 'funds_raised_millions' column to integer type (if necessary)
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN funds_raised_millions INT;

-- Update 'total_laid_off' column to integer type (if necessary)
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN total_laid_off INT;

-- Find the maximum total laid off value after conversion (if applicable)
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

**Analyzing Layoff Percentages:**

-- Find the maximum and minimum percentage laid off (excluding null values)
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- Identify companies with 100% layoffs
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;
-- These seem to be mostly startups that went out of business during this period.

-- Order companies with 100% layoffs by total laid off (highest first)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Order companies with 100% layoffs by funds raised (highest first)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- BritishVolt (EV company) and Quibi are interesting examples (large funding followed by closure).

**Grouped Analysis:**

-- Companies with the biggest single layoff event (top 5) based on total laid off
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;
-- This only considers a single day's data.

-- Companies with the most total layoffs overall
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
-- LIMIT 10;

-- Date range of layoffs in the data set
SELECT MIN(date), MAX(date)
FROM world_layoffs.layoffs_staging2;

-- Industries with the most layoffs (total)
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Top 10 locations with the most layoffs (total)
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- Total layoffs per country
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Total layoffs per year
SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 DESC;

-- Industries with the most layoffs (total)
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Layoffs by funding stage (total)
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

**More Complex Queries:**

-- Rolling total of layoffs per month
SELECT SUBSTRING(date, 1, 7) AS MONTH, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY MONTH
ORDER BY MONTH ASC;

-- CTE (Common Table Expression) for calculating rolling totals
WITH Rolling_Total AS (
  SELECT SUBSTRING(date, 1, 7) AS MONTH, SUM(total_laid_off) AS total_laid_off
  FROM world_layoffs.layoffs_staging2
  WHERE SUBSTRING(date, 1, 7) IS NOT NULL
  GROUP BY MONTH
  ORDER BY 1 ASC
)
SELECT MONTH, total_laid_off, SUM(total_laid_off) OVER (ORDER BY MONTH) AS Rolling_total
FROM Rolling_Total;

-- **Companies with Most Layoffs Per Year:**

-- Previous query showed total layoffs per company (all years combined)
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Layoffs per company per year
SELECT company, YEAR(date) AS Years, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY company, YEAR(date)
ORDER BY company ASC;

-- Identify companies with the top 5 most layoffs per year
WITH Company_Year (Company, Years, Total_laid_off) AS (
  SELECT company, YEAR(date) AS Years, SUM(total_laid_off) AS total_laid_off
  FROM world_layoffs.layoffs_staging2
  GROUP BY company, YEAR(date)
),
Company_Year_Rank AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY Years ORDER BY total_laid_off DESC) AS Ranking
  FROM Company_Year
  WHERE Years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- **Identify Seasonal Layoff Trends:**
-- This query groups layoffs by month and displays the total layoffs for each month. You can then visualize this data to identify any seasonal patterns.
SELECT MONTH(date) AS month, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY MONTH(date)
ORDER BY month ASC;

-- **Correlations:**

-- **Layoffs vs. Funding Raised**
SELECT company, SUM(total_laid_off) AS total_laid_off, AVG(funds_raised_millions) AS avg_funding
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- **Layoffs vs. Industry or Country**
-- These queries group layoffs by industry and country, respectively.
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

SELECT country, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;









