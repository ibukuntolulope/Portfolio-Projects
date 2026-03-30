# NHS A&E Performance Analysis — SQL Portfolio Project

> **Full-year analysis of NHS Accident & Emergency performance across England (2023-24) using MySQL**

---

## Project Summary

This project analyses 2,424 rows of real NHS performance data covering 125 trusts across 7 NHS England regions. Using publicly available monthly statistics from NHS England, I built a series of SQL queries of increasing complexity to answer six analytical questions about A&E performance, trust benchmarking, and patient safety metrics.

The NHS 4-hour target requires 95% of patients to be seen, treated and either admitted or discharged within 4 hours. This analysis examines how far the NHS fell short of that target in 2023-24 — and which trusts performed best and worst.

---

## Key Findings

- The national 4-hour breach rate rose from **34.5% in April 2023** to a peak of **45.7% in December 2023** — between 7 and 9 times worse than the NHS target
- **United Lincolnshire Hospitals** had the worst breach rate in England at **60.9%**
- **University Hospitals Birmingham** recorded **20,278 patients** waiting 12+ hours after a decision to admit — averaging 1,690 per month
- Only **16 of 125 trusts** (13%) rated Good across both the 4-hour and 12-hour metrics
- **London** showed the greatest regional variation — 39 percentage points between its best (Homerton 19%) and worst (Hillingdon 58.3%) trust

---

## Dataset

| Detail | Value |
|--------|-------|
| Source | NHS England Official Statistics |
| URL | https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ |
| Period | April 2023 to March 2024 (full financial year) |
| Rows | 2,424 |
| Trusts | 125 NHS organisations |
| Regions | 7 NHS England regions |
| Columns | 23 (period, org details, 21 performance metrics) |
| Licence | Open Government Licence v3.0 |

---

## Tools

- **MySQL 8.0** — all analysis queries
- **MySQL Workbench** — query editor and import wizard
- **Microsoft Excel / Power Query** — combining and cleaning 12 monthly CSV files

---

## Repository Structure

```
nhs-ae-analysis/
│
├── data/
│   └── ae_2023_24_combined.csv        # Combined cleaned dataset (12 months)
│
├── sql/
│   ├── 00_setup.sql                   # Create database and table
│   ├── 01_worst_breach_rate.sql       # Question 1 — worst trusts by breach rate
│   ├── 02_monthly_trend.sql           # Question 2 — national trend month by month
│   ├── 03_most_improved.sql           # Question 3 — trusts that improved most
│   ├── 04_regional_rankings.sql       # Question 4 — RANK() within each region
│   ├── 05_12hr_lag_analysis.sql       # Question 5 — LAG() month-on-month changes
│   └── 06_performance_scorecard.sql   # Question 6 — full multi-metric scorecard
│
├── NHS_AE_Portfolio_Project.docx      # Full written analysis and findings
└── README.md
```

---

## SQL Concepts Covered

| Challenge | Concepts |
|-----------|----------|
| 1 — Worst breach rates | `SELECT`, `SUM`, `ROUND`, `GROUP BY`, `ORDER BY`, `LIMIT` |
| 2 — Monthly trend | Time series aggregation, grouping by date |
| 3 — Most improved trusts | `CASE WHEN`, CTE (`WITH`), self-`JOIN` |
| 4 — Regional rankings | `RANK()`, `PARTITION BY`, window functions |
| 5 — 12-hour DTA waits | `LAG()`, `OVER()`, month-on-month change |
| 6 — Performance scorecard | Chained CTEs, multi-metric `RANK()`, `CASE WHEN` rating |

---

## How to Reproduce

### 1. Download the data

Go to the [NHS England A&E statistics page](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2023-24/) and download all 12 monthly CSV files for 2023-24.

### 2. Combine and clean

Open a blank Excel workbook and use **Data → Get Data → From File → From Folder** to combine all 12 files using Power Query. Apply the following M formula to convert the period column to a proper date:

```
let parts = Text.Split([Period], "-") in
Date.FromText(parts{2} & "-" &
  (if parts{1} = "JANUARY" then "01" else
   if parts{1} = "FEBRUARY" then "02" else
   if parts{1} = "MARCH" then "03" else
   if parts{1} = "APRIL" then "04" else
   if parts{1} = "MAY" then "05" else
   if parts{1} = "JUNE" then "06" else
   if parts{1} = "JULY" then "07" else
   if parts{1} = "AUGUST" then "08" else
   if parts{1} = "SEPTEMBER" then "09" else
   if parts{1} = "OCTOBER" then "10" else
   if parts{1} = "NOVEMBER" then "11" else "12") & "-01")
```

Remove the TOTAL summary row, then save as **CSV UTF-8**.

### 3. Set up MySQL

Run `sql/00_setup.sql` in MySQL Workbench to create the database and table:

```sql
CREATE DATABASE IF NOT EXISTS nhs_ae;
USE nhs_ae;

CREATE TABLE ae_waiting_times (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  period                DATE,
  org_code              VARCHAR(10),
  parent_org            VARCHAR(100),
  org_name              VARCHAR(200),
  att_type1             INT,
  att_type2             INT,
  att_other             INT,
  att_booked_type1      INT,
  att_booked_type2      INT,
  att_booked_other      INT,
  over4hr_type1         INT,
  over4hr_type2         INT,
  over4hr_other         INT,
  over4hr_booked_type1  INT,
  over4hr_booked_type2  INT,
  over4hr_booked_other  INT,
  wait_4_12hr_dta       INT,
  wait_12hr_plus_dta    INT,
  emg_adm_type1         INT,
  emg_adm_type2         INT,
  emg_adm_other         INT,
  emg_adm_other_non_ae  INT
);
```

### 4. Import the data

Right-click `ae_waiting_times` in MySQL Workbench → **Table Data Import Wizard** → browse to your combined CSV → map columns → import.

### 5. Run the analysis

Run each SQL file in the `sql/` folder in order.

---

## Data Dictionary

| Column | Type | Description |
|--------|------|-------------|
| `period` | DATE | Reporting month (first day of month) |
| `org_code` | VARCHAR | Unique NHS organisation code |
| `parent_org` | VARCHAR | NHS England region |
| `org_name` | VARCHAR | Full organisation name |
| `att_type1` | INT | Type 1 (major A&E) attendances |
| `att_type2` | INT | Type 2 (single specialty) attendances |
| `att_other` | INT | Other A&E (UTC/walk-in) attendances |
| `att_booked_type1` | INT | Booked appointments — Type 1 |
| `att_booked_type2` | INT | Booked appointments — Type 2 |
| `att_booked_other` | INT | Booked appointments — Other |
| `over4hr_type1` | INT | Attendances over 4 hours — Type 1 |
| `over4hr_type2` | INT | Attendances over 4 hours — Type 2 |
| `over4hr_other` | INT | Attendances over 4 hours — Other |
| `over4hr_booked_type1` | INT | Over 4hrs among booked Type 1 |
| `over4hr_booked_type2` | INT | Over 4hrs among booked Type 2 |
| `over4hr_booked_other` | INT | Over 4hrs among booked Other |
| `wait_4_12hr_dta` | INT | Patients waiting 4–12hrs after decision to admit |
| `wait_12hr_plus_dta` | INT | Patients waiting 12+ hrs after decision to admit |
| `emg_adm_type1` | INT | Emergency admissions via Type 1 A&E |
| `emg_adm_type2` | INT | Emergency admissions via Type 2 A&E |
| `emg_adm_other` | INT | Emergency admissions via Other A&E |
| `emg_adm_other_non_ae` | INT | Other emergency admissions (non A&E route) |

---

## About the NHS Metrics

**Type 1** — Major A&E departments at general hospitals. This is where the 4-hour target applies and where the most seriously ill patients are treated.

**Type 2** — Single specialty departments such as ophthalmology or dental A&E.

**Other (Type 3)** — Urgent Treatment Centres, walk-in centres, and minor injury units. These handle less serious cases.

**4-hour breach** — A patient who spent more than 4 hours in A&E from arrival to discharge or admission. The NHS target is that no more than 5% of patients should breach this threshold.

**12-hour DTA wait** — A patient who waited 12 or more hours in A&E after a doctor decided they needed to be admitted to a ward. This is considered a serious patient safety concern.

---

## Licence

Data is published by NHS England under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

Analysis and SQL code in this repository are free to use and adapt.
