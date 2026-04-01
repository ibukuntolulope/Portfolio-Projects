# NHS A&E Performance and Opioid Prescribing Analysis
SQL Portfolio Project | England 2023-24

---

## What this project is about

I wanted to practise SQL on data that actually matters, so I used real NHS datasets that are freely available to the public. The project looks at how NHS A&E departments performed across England in 2023-24 and then goes a step further by joining that data to GP opioid prescribing figures to see whether regions with higher prescribing rates also tend to have worse A&E performance.

Everything was built in MySQL Workbench from scratch, starting with basic queries and working up to window functions, CTEs and cross-dataset joins.

---

## The headline numbers

- Only 16 of 125 major A&E trusts (13%) hit Good performance across both key metrics
- 47 trusts (38%) rated Poor, meaning nearly 4 in 10 NHS trusts were operating at crisis level throughout the year
- The national 4-hour breach rate got worse every month from 34.5% in April 2023 to a peak of 45.7% in December 2023
- University Hospitals Birmingham had the worst 12-hour trolley wait figures in the country, with 20,278 patients stuck in A&E after a doctor said they needed a bed
- The Midlands ranked worst on both opioid prescribing volume and A&E breach rate

---

## Data sources

| Dataset | Source | Period | Rows |
|---------|--------|--------|------|
| A&E Attendances and Emergency Admissions | [NHS England Statistics](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/) | Apr 2023 to Mar 2024 | 2,424 |
| GP Prescribing Data (opioids filtered) | [NHS BSA Open Data Portal](https://opendata.nhsbsa.net/dataset/english-prescribing-data-epd) | April 2023 | 408,584 |

Both are published under the Open Government Licence v3.0 and are free to download.

---

## SQL skills covered

| Task | What I used | Question it answered |
|-----------|-------------|----------------------|
| 1 | SELECT, SUM, ROUND, GROUP BY, ORDER BY, LIMIT | Which 10 trusts had the worst 4-hour breach rate? |
| 2 | GROUP BY on a date column, time series | How did the national breach rate change month by month? |
| 3 | CASE WHEN, CTE, self-JOIN | Which trusts improved the most between the first and second half of the year? |
| 4 | RANK(), PARTITION BY, window functions | How does each trust rank within its own NHS region? |
| 5 | LAG(), window functions | How did 12-hour trolley waits change month on month at each trust? |
| 6 | Chained CTEs, multi-metric scorecard | Build a full performance scorecard rating every trust Good, Average or Poor |
| 7 | Cross-dataset JOIN, CONCAT for key matching | Is there a link between opioid prescribing and A&E performance by region? |

---

## Project structure

```
nhs-sql-analysis/
│
├── data/
│   └── README.md              # How to download the source data
│
├── sql/
│   ├── 01_setup.sql           # Create database and tables
│   ├── 02_Task1.sql      # Worst breach rates by trust
│   ├── 03_Task2.sql      # Monthly national trend
│   ├── 04_Task3.sql      # First vs second half comparison
│   ├── 05_Task4.sql      # Regional rankings with RANK()
│   ├── 06_Task5.sql      # 12-hour waits with LAG()
│   ├── 07_Task6.sql      # Full trust scorecard
│   └── 08_Task7.sql      # Cross-dataset JOIN analysis
│
├── python/
│   ├── combine_nhs_ae.py      # Combine 12 monthly A&E CSVs into one file
│   ├── filter_opioids.py      # Pull opioid rows from 17M row prescribing file
│   ├── clean_opioids.py       # Fix line endings before MySQL import
│   └── load_opioids.py        # Load filtered data into MySQL
│
└── README.md
```

---

## How to reproduce this

### What you need
- MySQL Workbench 8.0 or later
- Python 3.8 or later
- Run `pip install pandas mysql-connector-python` to install the required libraries

### Step 1 - Download the A&E data
Go to the [NHS England A&E 2023-24 page](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2023-24/) and download all 12 monthly CSV files.

### Step 2 - Combine the files in Excel
Open a blank Excel workbook, go to Data, Get Data, From File, then From Folder. Point it at the folder with all 12 CSVs and use Combine and Load. Add a custom column to convert the period format from MSitAE-APRIL-2023 to 2023-04-01. Remove any error rows and save as CSV UTF-8.

### Step 3 - Set up MySQL
Run `sql/01_setup.sql` in MySQL Workbench to create the nhs_ae database and tables.

### Step 4 - Import the A&E data
Use the Table Data Import Wizard in MySQL Workbench to load your combined CSV into ae_waiting_times.

### Step 5 - Get the prescribing data
Download the April 2023 EPD file from the [NHS BSA Open Data Portal](https://opendata.nhsbsa.net/dataset/english-prescribing-data-epd). The file has 17 million rows so run `python/filter_opioids.py` first to pull out only the opioid rows (BNF code starting with 0407010). Then run `python/clean_opioids.py` and `python/load_opioids.py` to load it into MySQL.

### Step 6 - Run the queries
Work through the SQL files in the sql folder in order.

---

## Key results

### Trust performance scorecard

| Rating | How it was defined | Number of trusts | Share |
|--------|--------------------|-----------------|-------|
| Good | Breach rate below 35% and total 12-hour waits below 500 | 16 | 13% |
| Average | Neither Good nor Poor | 62 | 50% |
| Poor | Breach rate above 50% or total 12-hour waits above 5,000 | 47 | 38% |

### Regional opioid prescribing vs A&E performance

| Region | Opioid prescriptions | Breach rate | 12-hour waits |
|--------|---------------------|-------------|---------------|
| Midlands | 569,444 | 45.1% | 105,867 |
| North East and Yorkshire | 485,629 | 39.6% | 38,989 |
| North West | 434,990 | 43.6% | 101,884 |
| South East | 324,819 | 37.2% | 45,077 |
| South West | 264,857 | 42.1% | 34,729 |
| East of England | 258,483 | 41.5% | 31,293 |
| London | 249,263 | 40.3% | 81,572 |

---

## Tools used

| Tool | What it was used for |
|------|----------------------|
| MySQL Workbench 8.0 | All SQL analysis |
| Microsoft Excel with Power Query | Combining and cleaning the 12 monthly CSV files |
| Python with pandas | Filtering the 17 million row prescribing dataset down to opioids only |
| Python with mysql-connector | Loading the filtered data into MySQL |

---

## A note on data quality

A handful of things to be aware of if you use this data yourself. Mid Yorkshire Hospitals shows a 0.0% breach rate which is almost certainly a reporting issue rather than genuine performance. Kettering General and Milton Keynes both show zero 12-hour waits which also looks like it may be missing data. The opioid prescribing analysis only covers one month so the regional comparison is indicative rather than definitive. And the correlation between opioid prescribing and A&E performance is just that, a correlation, not evidence of a causal link.

---

## Licence

NHS data is published under the Open Government Licence v3.0. The code in this repository is available under the MIT Licence.
