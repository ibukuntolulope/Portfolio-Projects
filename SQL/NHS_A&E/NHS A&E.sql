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

-- OR

WITH trust_stats AS (
    SELECT
        org_name,
        ROUND(100.0 * SUM(over4hr_type1) / SUM(att_type1), 1) AS breach_pct,
        SUM(wait_12hr_plus_dta) AS total_12hr_waits
    FROM ae_waiting_times
    WHERE att_type1 > 0
    GROUP BY org_name
),
rated AS (
    SELECT
        org_name,
        breach_pct,
        total_12hr_waits,
        CASE
            WHEN breach_pct < 35 AND total_12hr_waits < 500  THEN 'Good'
            WHEN breach_pct > 50 OR  total_12hr_waits > 5000 THEN 'Poor'
            ELSE 'Average'
        END AS rating
    FROM trust_stats
)
SELECT 
    rating,
    COUNT(*) AS number_of_trusts
FROM rated
GROUP BY rating
ORDER BY number_of_trusts DESC;

/*NOTE TO SOLUTION 6
Out of 125 major A&E trusts in England in 2023-24:

47 Poor (38%) — nearly 4 in 10 trusts in crisis
62 Average (50%) — half the country struggling but not at crisis level
16 Good (13%) — only 1 in 8 trusts genuinely performing well

That means 87% of NHS trusts are failing to meet acceptable A&E standards when you combine Poor and Average together. This is not a localised problem — it is a nationwide systemic failure.

The worst trusts — Poor rating deep dive
University Hospitals Birmingham is the single most concerning trust in the entire dataset — 20,278 twelve-hour waits across the year averaging 1,690 patients every single month stuck in A&E after a doctor said they needed a bed. They are also ranked 33rd worst for breach rate at 47.1% — so they are failing on both measures simultaneously at enormous scale. They see 391,673 Type 1 patients a year, the busiest trust in the dataset but size alone doesn't explain this. Liverpool sees 201,974 patients and still racks up 14,118 twelve-hour waits. Scale is clearly a factor but not the whole story.
East Kent is arguably the most consistently poor performer but never dropping below 769 twelve-hour waits even in summer, finishing the year with 12,715 total. Their breach rate of 53.9% is the worst in the South East. This trust has been in special measures before and this data suggests the problems are deeply entrenched.
East Lancashire is the hidden crisis trust which ranked only 95th for breach rate at 36.5% which looks almost acceptable, but ranked 4th worst nationally for twelve-hour waits with 12,903 patients. This tells a very specific story, patients are moving through A&E at a reasonable pace but there are simply no beds to admit them to. This is a whole-hospital capacity problem, not an A&E problem.
Epsom and St Helier is the most misleading trust in the dataset at first glance, a breach rate of just 24.7% would suggest good performance, yet they rate Poor due to 6,473 twelve-hour waits. This is a perfect example of why a single metric is dangerous in performance analysis. Their A&E is fast but their bed management is in crisis.
Countess of Chester rates Poor — 7,337 twelve-hour waits — yet their breach rate of 48.4% puts them only 27th worst. Again, two very different problems happening simultaneously.

The Good trusts — what genuine excellence looks like
Maidstone and Tunbridge Wells is the standout performer in the entire country with 16.4% breach rate (the best non-specialist adult trust) and only 322 twelve-hour waits. They see 215,773 patients a year — this is not a quiet rural hospital. Something is genuinely working differently here and it deserves investigation.
Calderdale and Huddersfield is perhaps the most impressive result in context, 177,149 attendances with only 23 twelve-hour waits all year. Compare that directly to Lewisham and Greenwich who see a similar volume of 158,517 patients but had 6,895 twelve-hour waits. Same workload, completely different outcomes. The gap between these two trusts is one of the most striking findings in the entire dataset.
Northumbria Healthcare rates Good with a 23.5% breach rate and just 19 twelve-hour waits, remarkable for a trust covering a large geographic area in the North East.
Chelsea and Westminster sees 226,315 patients — one of the busiest trusts in London, yet manages a 22.9% breach rate and only 410 twelve-hour waits. In a region where Hillingdon manages 58.3% breaches and King's College has nearly 8,000 twelve-hour waits, Chelsea and Westminster look like a different NHS entirely.

The most important analytical findings
Finding 1 — Breach rate and twelve-hour waits are measuring different problems. A trust can fail badly on one and perform well on the other. Sheffield Teaching Hospitals has a 50.1% breach rate but only 100 twelve-hour waits — their A&E is slow but beds are available. East Lancashire has a 36.5% breach rate but 12,903 twelve-hour waits — their A&E moves quickly but the hospital behind it is full. These require completely different solutions.
Finding 2 — Geography is not destiny. Every region has both Poor and Good trusts. London has Homerton at 19% breach and Hillingdon at 58.3%. The North East has Sheffield Children's at 9.9% and York and Scarborough at 56.4%. Local management, culture, and capacity decisions matter enormously.
Finding 3 — Volume does not explain performance. Some of the busiest trusts rate Good. Some of the smallest trusts rate Poor. The Isle of Wight with only 44,547 attendances rates Average with 3,243 twelve-hour waits. Mid and South Essex with 365,357 attendances — the highest in the dataset — rates Good with only 236 twelve-hour waits.
Finding 4 — The winter cliff edge is universal. Every single trust without exception showed a dramatic worsening from October 2023 onwards. This is not about individual trust management — it is about a healthcare system without enough winter capacity built in.
Finding 5 — Data quality remains a concern. Mid Yorkshire showing 0.0% breach rate, Kettering and Milton Keynes showing zero twelve-hour waits, and several trusts with missing months all suggest reporting inconsistencies that would need investigating before using this data in a formal report.

In conclusion
The 2023-24 NHS A&E data tells a story of a system under extreme and widespread pressure. The 16 Good trusts prove that high performance is achievable within the NHS. The question is why the other 109 trusts cannot replicate it. The answer almost certainly lies in bed availability, community care capacity, and workforce levels rather than A&E management alone. A&E is where the pressure shows, but the causes are deeper in the system.

===================
*/

