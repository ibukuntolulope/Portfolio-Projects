/* Question 7 - Cross dataset JOIN
Is there a link between opioid prescribing and A&E performance by region?
*/

USE nhs_ae;
DROP TABLE gp_prescribing;

CREATE TABLE gp_prescribing (
  id                          INT AUTO_INCREMENT PRIMARY KEY,
  `year_month`                INT,
  regional_office_name        VARCHAR(100),
  regional_office_code        VARCHAR(20),
  icb_name                    VARCHAR(150),
  icb_code                    VARCHAR(20),
  pco_name                    VARCHAR(150),
  pco_code                    VARCHAR(20),
  practice_name               VARCHAR(150),
  practice_code               VARCHAR(20),
  address_1                   VARCHAR(200),
  address_2                   VARCHAR(200),
  address_3                   VARCHAR(200),
  address_4                   VARCHAR(200),
  postcode                    VARCHAR(20),
  bnf_chemical_substance      VARCHAR(20),
  chemical_substance_descr    VARCHAR(200),
  bnf_code                    VARCHAR(20),
  bnf_description             VARCHAR(200),
  bnf_chapter_plus_code       VARCHAR(100),
  quantity                    DECIMAL(15,2),
  items                       INT,
  total_quantity              DECIMAL(15,2),
  adqusage                    DECIMAL(15,4),
  nic                         DECIMAL(15,2),
  actual_cost                 DECIMAL(15,2),
  unidentified                VARCHAR(10),
  snomed_code                 VARCHAR(30)
);

SELECT COUNT(*) FROM gp_prescribing;

-- Check row count
SELECT COUNT(*) AS total_rows FROM gp_prescribing;

-- Preview the data
SELECT 
    regional_office_name,
    chemical_substance_descr,
    SUM(items) AS total_prescriptions,
    ROUND(SUM(nic), 2) AS total_cost_gbp
FROM gp_prescribing
GROUP BY regional_office_name, chemical_substance_descr
ORDER BY total_prescriptions DESC
LIMIT 10;

/* First Trial
WITH opioid_by_region AS (
    SELECT
        regional_office_name,
        SUM(items)          AS total_opioid_prescriptions,
        ROUND(SUM(nic), 2)  AS total_opioid_cost
    FROM gp_prescribing
    GROUP BY regional_office_name
),
ae_by_region AS (
    SELECT
        parent_org,
        COUNT(DISTINCT org_name)                                    AS num_trusts,
        SUM(att_type1)                                              AS total_ae_attendances,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1)      AS breach_pct,
        SUM(wait_12hr_plus_dta)                                     AS total_12hr_waits
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY parent_org
)
SELECT
    o.regional_office_name                          AS region,
    o.total_opioid_prescriptions,
    o.total_opioid_cost,
    a.total_ae_attendances,
    a.breach_pct,
    a.total_12hr_waits,
    ROUND(o.total_opioid_prescriptions / a.num_trusts, 0) AS opioid_prescriptions_per_trust
FROM opioid_by_region o
JOIN ae_by_region a
    ON TRIM(o.regional_office_name) = TRIM(a.parent_org)
ORDER BY o.total_opioid_prescriptions DESC;
*/

-- Check region names in prescribing table
SELECT DISTINCT regional_office_name 
FROM gp_prescribing
ORDER BY regional_office_name;

-- Check region names in A&E table
SELECT DISTINCT parent_org 
FROM ae_waiting_times
ORDER BY parent_org;

-- SOLUTION - Cross dataset JOIN
WITH opioid_by_region AS (
    SELECT
        regional_office_name,
        SUM(items)          AS total_opioid_prescriptions,
        ROUND(SUM(nic), 2)  AS total_opioid_cost
    FROM gp_prescribing
    WHERE regional_office_name != 'UNIDENTIFIED'
    GROUP BY regional_office_name
),
ae_by_region AS (
    SELECT
        parent_org,
        COUNT(DISTINCT org_name)                               AS num_trusts,
        SUM(att_type1)                                         AS total_ae_attendances,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct,
        SUM(wait_12hr_plus_dta)                                AS total_12hr_waits
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY parent_org
)
SELECT
    o.regional_office_name                                        AS region,
    o.total_opioid_prescriptions,
    o.total_opioid_cost,
    a.total_ae_attendances,
    a.breach_pct,
    a.total_12hr_waits,
    ROUND(o.total_opioid_prescriptions / a.num_trusts, 0)        AS opioid_per_trust
FROM opioid_by_region o
JOIN ae_by_region a
    ON TRIM(a.parent_org) = CONCAT('NHS ENGLAND ', TRIM(o.regional_office_name))
ORDER BY o.total_opioid_prescriptions DESC;

/*-- NOTE TO SOLUTION 7
The results explained:
The columns are: region, opioid prescriptions, opioid cost, A&E attendances, breach %, 12hr waits, opioid prescriptions per trust.
Here are the key findings:
Midlands has the highest opioid prescribing at 569,444 prescriptions and also the worst A&E breach rate at 45.1% with 105,867 twelve-hour waits — the worst on both measures simultaneously.
London has the lowest opioid prescribing at 249,263 but a 40.3% breach rate and 81,572 twelve-hour waits, suggesting London's A&E pressures come from other factors like population density rather than opioid-related demand.
North West has high opioid prescribing at 434,990 and a 43.6% breach rate with 101,884 twelve-hour waits, second worst on most measures.
South East is interesting, with relatively lower opioid prescribing at 324,819 but still a 37.2% breach rate, suggesting better management despite similar pressures.

The emerging correlation:
Regions with higher opioid prescribing generally have higher A&E breach rates — Midlands, North East and Yorkshire, and North West all rank high on both. This is consistent with research showing areas with high chronic pain and opioid dependency tend to generate more unplanned A&E attendances.
However this is a correlation not causation, we'd need much more data to prove a causal link.
=====================
*/