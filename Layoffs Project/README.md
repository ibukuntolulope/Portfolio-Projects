## README Summary of MySQL Work for Layoffs Data Cleaning

This repository contains scripts for cleaning a dataset of layoffs obtained from [Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022). The focus is on creating a clean and standardized staging table (`world_layoffs.layoffs_staging2`) for further analysis.

**Steps Performed:**

1. **Duplicate Removal:**
    - Identified duplicates using `ROW_NUMBER()` with a `PARTITION BY` clause on relevant columns.
    - Created a temporary table (`layoffs_staging2`) to store non-duplicate rows.
    - Deleted duplicate rows from `layoffs_staging2`.

2. **Data Standardization:**
    - Removed leading/trailing whitespaces from the `company` column using `TRIM()`.
    - Addressed missing or empty values in the `industry` column:
        - Standardized variations like "Crypto Currency" to "Crypto".
        - Populated empty values using industry information from other rows with the same company name (if available).
        - Set remaining empty values to `NULL`.
    - Standardized country names by removing trailing periods (e.g., "United States." to "United States").
    - Converted the `date` column to a proper `DATE` data type using `STR_TO_DATE()` and handled potential "NONE" values appropriately.
    - (Commented out) Attempted to convert the `funds_raised_millions` column to an integer, but further review might be needed.

3. **Handling Null Values:**
    - Existing `NULL` values in `total_laid_off`, `percentage_laid_off`, and `funds_raised_millions` were left unchanged for potential future calculations.

4. **Removing Unnecessary Data:**
    - Removed rows with "NONE" values in both `total_laid_off` and `percentage_laid_off`.
    - Removed rows with "NONE" or empty values in the `industry` column, after attempting to populate them from other rows. 
    - (Commented out) Removed rows with `NULL` values in both `total_laid_off` and `percentage_laid_off`. This might be considered depending on your analysis needs.
    - Updated all remaining "NONE" values in various columns to `NULL`.
    - Removed the temporary `row_num` column added for duplicate identification.


**Additional Notes:**

- The original table (`world_layoffs.layoffs`) remains untouched for backup purposes.
- Comments are included throughout the scripts to explain the logic behind each step.

**Next Steps:**

- Explore the cleaned data in `world_layoffs.layoffs_staging2` for further analysis.
- Consider defining constraints on the table to prevent future data inconsistencies.
