DROP DATABASE IF EXISTS nhs_ae;

CREATE DATABASE nhs_ae;
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

/* DATA DICTIONARY
- The NHS splits A&E activity into 3 types. 
- Type 1 = major A&E (e.g. Royal Infirmary). 
- Type 2 = single specialty (e.g. eye hospital). 
- Other = urgent treatment centres, walk-in centres, minor injury units. 
- The 4-hour target only officially applies to Type 1.

Identity columns

- period DATE
The month this row of data covers. Always the 1st of the month.
e.g. 2023-04-01 = April 2023
- org_code TEXT
The unique NHS code for this organisation. Every NHS trust and provider has one.
e.g. RWY = Calderdale & Huddersfield, RRK = UHB Birmingham
- parent_org TEXT
The NHS England region this organisation belongs to. There are 7 regions across England.
e.g. NHS ENGLAND MIDLANDS, NHS ENGLAND LONDON
- org_name TEXT
The full name of the NHS trust or provider.
e.g. CALDERDALE AND HUDDERSFIELD NHS FOUNDATION TRUST

ATTENDANCES — HOW MANY PEOPLE CAME IN
- att_type1 INT
Total attendances at a major A&E department (Type 1). This is the main A&E metric — the big emergency departments at general hospitals.
e.g. 13,762 for Calderdale in April 2023
- att_type2 INT
Attendances at a single specialty A&E (Type 2), such as an eye hospital or dental emergency unit. Most trusts show 0 here.
e.g. Moorfields Eye Hospital has high Type 2 numbers
- att_other INT
Attendances at urgent treatment centres (UTCs), walk-in centres, and minor injury units. These handle less serious cases.
e.g. a walk-in centre seeing 8,675 patients in a month
- att_booked_type1 INT
Of the Type 1 attendances, how many had a pre-booked appointment (rather than just walking in).
e.g. 0 for most trusts — booked A&E appointments are still rare
- att_booked_type2 INT
Booked appointments at Type 2 (single specialty) departments.
e.g. eye clinics often have booked slots
- att_booked_other INT
Booked appointments at UTCs and walk-in centres.
e.g. some UTCs allow online booking

OVER 4-HOURS WAIT — THE KEY PERFORMANCE METRIC
- over4hr_type1 INT
Number of Type 1 patients who spent more than 4 hours in A&E from arrival to discharge/admission. The NHS target is that 95% of patients should be seen within 4 hours — this column measures failures against that target.
e.g. 3,865 breaches out of 13,762 = 28% breach rate
- over4hr_type2 INT
Over 4-hour waits at Type 2 departments.
e.g. usually small numbers
- over4hr_other INT
Over 4-hour waits at UTCs and walk-in centres.
e.g. walk-in centres rarely breach 4 hours
- over4hr_booked_type1 INT
Of the booked Type 1 appointments, how many still waited over 4 hours.
e.g. even pre-booked patients can face long waits
- over4hr_booked_type2 INT
Over 4-hour waits among booked Type 2 appointments.
- over4hr_booked_other INT
Over 4-hour waits among booked UTC/walk-in appointments.

- DECISION-TO-ADMIT WAITS - THE MOST SERIOUS DELAYS
- wait_4_12hr_dta INT
Patients who waited between 4 and 12 hours in A&E after a doctor decided they needed to be admitted to a ward (DTA = Decision To Admit). This means a bed wasn't available — the patient was stuck in A&E even though they needed a hospital bed.
e.g. 822 patients in Calderdale in April 2023
- wait_12hr_plus_dta INT
Patients who waited 12 or more hours after a decision to admit. This is the most serious measure — these patients needed a hospital bed urgently but waited half a day or more in A&E. This metric made national headlines during winter 2022-23.
e.g. 2 patients in Calderdale — nationally this hit 1,000s per day in winter

- EMERGENCY ADMISSIONS - PATIENTS ADMITTED VIA A &E
- emg_adm_type1 INT
Number of patients who came through the major A&E and were admitted to a hospital bed as an emergency. Roughly 25-30% of Type 1 attendances result in an admission.
e.g. 2,759 admissions from 13,762 attendances = 20% admission rate
- emg_adm_type2 INT
Emergency admissions via Type 2 departments.
e.g. eye emergencies requiring admission
- emg_adm_other INT
Emergency admissions via UTCs and walk-in centres. Usually low — these centres handle minor cases.
e.g. a walk-in centre that refers serious cases for admission
- emg_adm_other_non_ae INT
Emergency admissions that didn't come through any A&E route — for example direct GP referrals, ambulance admissions bypassing A&E, or admissions from other wards.
e.g. 802 at Calderdale — these are emergencies admitted without going through A&E
*/

-- Data Verification
SELECT *
FROM ae_waiting_times
LIMIT 5000;

USE nhs_ae;

SELECT 
	period, COUNT(*) AS num_trusts
FROM ae_waiting_times
GROUP BY period
ORDER BY period;

/* QUESTION 1
Which 10 NHS trusts had the worst 4-hour breach rate across the whole year?
*/

-- SOLUTION
SELECT 
    org_name,
    SUM(att_type1) AS total_type1_attendances,
    SUM(over4hr_type1) AS total_over_4hrs,
    ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct
FROM ae_waiting_times
WHERE att_type1 > 0
GROUP BY org_name
ORDER BY breach_pct DESC
LIMIT 10;

/* NOTE TO SOLUTION 1
==================
United Lincolnshire Hospitals had the worst performance — 60.9% of patients waited over 4 hours. That means more than 1 in every 2 patients wasn't seen within the NHS target time.
===================
*/


/* QUESTION 2
How did the national 4-hour breach rate change month by month across 2023-24?
*/

-- SOLUTION
SELECT 
    period,
    SUM(att_type1) AS total_type1_attendances,
    SUM(over4hr_type1) AS total_over_4hrs,
    ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct
FROM ae_waiting_times
WHERE att_type1 > 0
GROUP BY period
ORDER BY period ;

/* NOTE TO SOLUTION 2
=====================
The breach rate got steadily worse as the year went by.
April 2023 started at 34.5%,  already bad (the NHS target is only 5% breaches).
It increased every single month through summer and autumn seasons
Peaked in December 2023 at 45.7% which was nearly half of all patients waiting over 4 hours
Then slightly improved into March 2024 back down to 39.4%
This can also be related to the NHS winter pressure pattern where demand rises in autumn/winter, the beds fill up, and A&E gets really stuck
===================
*/


/* QUESTION 3 - CTE
Which trusts improved the most between the first and second half of the year?
*/

-- SOLUTION- USED 'WITH, CTE(Common Table Expression) & JOIN'

WITH half_year_stats AS (
    SELECT
        org_name,
        CASE WHEN period <= '2023-09-01' THEN 'first_half'
             ELSE 'second_half'
        END AS half_year,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY org_name, half_year
)
SELECT
    first.org_name,
    first.breach_pct  AS first_half_pct,
    second.breach_pct AS second_half_pct,
    ROUND(first.breach_pct - second.breach_pct, 1) AS improvement
FROM half_year_stats first
JOIN half_year_stats second
    ON first.org_name = second.org_name
    AND first.half_year = 'first_half'
    AND second.half_year = 'second_half'
WHERE first.breach_pct - second.breach_pct > 0
ORDER BY improvement DESC
LIMIT 10;

/* NOTE TO SOLUTION 3
=====================
- University Hospitals of Derby and Burton was the biggest improver and their breach rate dropped from 51.2% down to 44.4%, an improvement of 6.8 percentage points. That means roughly 1 in 15 extra patients were being seen within 4 hours by the second half of the year compared to the first.
- Barking, Havering and Redbridge improved by 4.7 points, but notice they still had 48.7% breaching in the second half, so they improved but were still struggling badly.
- Homerton Healthcare is interesting as they only improved by 2.2 points BUT their breach rate was already very low at 20.1% in the first half. That's actually excellent performance — most trusts were at 40-50%.
Buckinghamshire at the bottom only improved by 0.6 points — barely any change at all.

- Seeing the bigger picture with analysis:
Even the most improved trust only got better by 6.8 percentage points. Reference to solution 2, which confirmed that the national breach rate was around 40-45% all year.So while some trusts improved, nobody got anywhere close to the 95% target (meaning only 5% breaching). This tells confirmed that the NHS A&E crisis in 2023-24 was systemic and not just a few poorly performing trusts.
===================
*/


/* QUESTION 4 - window functions
 Rank every trust by breach rate within their NHS region
*/

-- SOLUTION -  window functions

WITH trust_breach AS (
    SELECT
        org_name,
        parent_org,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY org_name, parent_org
)
SELECT
    parent_org,
    org_name,
    breach_pct,
    RANK() OVER (
        PARTITION BY parent_org
        ORDER BY breach_pct DESC
    ) AS rank_in_region
FROM trust_breach
ORDER BY parent_org, rank_in_region;

/*NOTE TO SOLUTION 4
- Best performing trusts — Homerton (London) 19%, Chelsea & Westminster 22.9%, Maidstone & Tunbridge Wells 16.4%. These are the standout performers.
- Worst performing trusts — United Lincolnshire 60.9%, Hillingdon 58.3%, Royal Cornwall 55.8%. Nearly 2 in every 3 patients waiting over 4 hours.
- Best region overall — London, but only because of a few star performers dragging the average down. It also has some of the worst trusts.
 Worst region overall — Midlands, with the most trusts consistently above 45%.
- Biggest gap within a region — London, with 39 percentage points between its best (Homerton 19%) and worst (Hillingdon 58.3%) trust.
- Data quality flag — Mid Yorkshire showing 0.0% is almost certainly a reporting issue, not real performance.

With the analysis, even the "good" trusts like Homerton at 19% are still missing the NHS 95% target badly. The target means only 5% should breach and so even the best trust is nearly 4 times worse than the target.
===================
*/


/* QUESTION 5- LAG
 Which trusts had the worst 12-hour trolley waits, and how did it change month by month?
*/

-- SOLUTION

SELECT 
	org_name,
    period,
    wait_12hr_plus_dta,
    LAG(wait_12hr_plus_dta) OVER(
		PARTITION BY org_name
        ORDER BY period
        ) AS prev_month,
        wait_12hr_plus_dta - LAG(wait_12hr_plus_dta) OVER(
			PARTITION BY org_name
			ORDER BY period
        ) AS monthly_change
FROM ae_waiting_times
WHERE wait_12hr_plus_dta > 0
ORDER BY org_name, period;

/*NOTE TO SOLUTION 5
The overall pattern for every trust, every month
Almost universally, numbers were low in spring/summer 2023 then exploded upward from October onwards, peaking in January 2024, then slightly easing into March 2024. This is the classic NHS winter crisis playing out in raw numbers.

- The worst offenders — highest 12-hour waits
University Hospitals Birmingham is the standout, hitting 2,453 patients in January 2024. That means on average 79 patients every single day were stuck in A&E for 12+ hours after a doctor said they needed a bed. This is a genuine patient safety crisis in numbers.
University Hospitals of Leicester hit 1,625 in January 2024, East Lancashire consistently stayed above 1,000 almost every month all year — meaning they never got on top of it even in summer.
East Kent is particularly alarming and they never dropped below 769 in any month, even in summer when most trusts improved. That suggests a structural problem, not just winter pressure.

- The most dramatic single-month spikes
Some trusts had sudden catastrophic months:

University Hospitals Sussex jumped from 985 to 1,813 in November 2023 — an extra 828 patients in one month
Manchester University jumped from 191 to 552 in December 2023 — a 361 increase almost overnight
Mid Yorkshire Teaching jumped from 309 to 660 in January 2024 — doubling in one month

These sudden spikes suggest a specific crisis event — a ward closure, a staffing shortage, or a norovirus outbreak rather than gradual pressure.

- The best performers are trusts keeping numbers low
Calderdale and Huddersfield never exceeded 7 patients in any month — remarkably controlled all year. Sheffield Teaching Hospitals similarly stayed in single digits most months despite being a large trust. South Warwickshire and Harrogate also kept numbers very low.
These trusts are worth studying — what are they doing differently? Better bed management? More community care? Fewer emergency admissions?
===================
*/


/* QUESTION 6- CTEs, window functions, aggregation 
 Build a full trust performance scorecard
*/

-- SOLUTION- CTEs, window functions, aggregation 

WITH trust_stats AS (
    SELECT
        org_name,
        parent_org,
        SUM(att_type1)                                             AS total_attendances,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1)      AS breach_pct,
        SUM(wait_12hr_plus_dta)                                     AS total_12hr_waits,
        ROUND(AVG(wait_12hr_plus_dta), 0)                          AS avg_monthly_12hr
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY org_name, parent_org
),
ranked AS (
    SELECT
        org_name,
        parent_org,
        total_attendances,
        breach_pct,
        total_12hr_waits,
        avg_monthly_12hr,
        RANK() OVER (ORDER BY breach_pct DESC)      AS national_rank_breach,
        RANK() OVER (ORDER BY total_12hr_waits DESC) AS national_rank_12hr,
        CASE
            WHEN breach_pct < 35 AND total_12hr_waits < 500   THEN 'Good'
            WHEN breach_pct > 50 OR  total_12hr_waits > 5000  THEN 'Poor'
            ELSE 'Average'
        END AS rating
    FROM trust_stats
)
SELECT *
FROM ranked
ORDER BY national_rank_breach;

/*NOTE TO SOLUTION 6
The headline numbersOut of 125 trusts rated:

37 rated Poor — over 1 in 4 trusts failing badly
72 rated Average — performing but still missing the target significantly
16 rated Good — only 1 in 8 trusts performing well
The worst trust in EnglandUniversity Hospitals Birmingham stands out above everyone else — rank 1 for 12-hour waits with a staggering 20,278 patients waiting 12+ hours across the year. That's an average of 1,690 patients every single month. They also had the highest total attendances at 391,673 — they are the busiest and most pressured trust in the country.The most dangerous combinationSome trusts are both high breach rate AND high 12-hour waits — the worst of both worlds:
East Kent — 53.9% breach rate AND 12,715 total 12-hour waits — ranked 10th worst for breach, 5th worst for 12-hour waits
United Lincolnshire — worst breach rate in England at 60.9% AND 11,009 12-hour waits
University Hospitals of Leicester — 46.2% breach AND 13,379 12-hour waits — ranked 3rd worst nationally for 12-hour waits
East Lancashire — 36.5% breach rate but 12,903 12-hour waits — ranked 4th worst nationally. Their breach rate looks moderate but their 12-hour waits tell a far worse story
The surprising outliersEpsom and St Helier is the most interesting anomaly in the entire dataset — their breach rate is only 24.7% which looks Good, but they have 6,473 total 12-hour waits which is rated Poor. This means patients are generally being seen within 4 hours, but once a doctor decides to admit them, they're then stuck waiting for a bed for 12+ hours. Two completely different problems happening at the same trust.St George's University Hospitals has a decent breach rate of 33% — which would normally rate Good — but 6,878 12-hour waits drags them to Poor. Same pattern as Epsom.County Durham and Darlington is the opposite — 48.1% breach rate which looks terrible, but only 148 total 12-hour waits all year. Patients wait a long time in A&E but once admitted they get a bed quickly.The genuinely Good performersThe 16 Good trusts fall into two categories:Specialist hospitals — Alder Hey Children's, Sheffield Children's, Birmingham Women's and Children's — these treat a different patient population so direct comparison isn't entirely fair.Genuinely high performing adult trusts — the ones worth paying attention to:

Maidstone and Tunbridge Wells — 16.4% breach, 322 12-hour waits — best performing large adult trust in England
Northumbria Healthcare — 23.5% breach, only 19 total 12-hour waits all year — extraordinary
Calderdale and Huddersfield — 30.7% breach, only 23 total 12-hour waits — consistently excellent
Chelsea and Westminster — 22.9% breach, 410 12-hour waits — excellent for a large London trust
The regional story in one line each
Midlands — dominated by Poor ratings, worst region overall
London — most polarised — both the best and worst trusts in England are here
North West — consistently Average to Poor, no standout performers
North East and Yorkshire — most variation — from Sheffield Children's at 9.9% to York at 56.4%
South East — split between Poor coastal trusts and Good inland tru
East of England — quietly struggling — several trusts with high 12-hour waits that don't make headlines


The key analytical insight
The rating column exposes something important — breach rate and 12-hour waits tell different stories. A trust can look Average on one metric and catastrophic on another. This is exactly why real NHS analysts build multi-metric scorecards rather than relying on a single headline number.
===================
*/

