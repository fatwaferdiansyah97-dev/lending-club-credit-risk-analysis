# Credit Risk and Control Effectiveness Analysis, Lending Club (2007 to 2018)

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/shared/KF5Y2HRP4?:display_count=n&:origin=viz_share_link)**

Analysis of 2,260,668 loan records, framed the way an audit would frame it: not only how large the risk is, but whether the control that is supposed to reduce it actually works.

By [Fatwa Ferdiansyah](https://github.com/fatwaferdiansyah97-dev) · [LinkedIn](https://www.linkedin.com/in/fatwa-ferdiansyah-9951ba278) · [Portfolio](https://fatwaferdiansyah97-dev.github.io/data-analyst-portfolio/)

---

## Problem Statement

A lending business rests on one capability: judging default risk accurately. This project answers two questions.

1. **Does loan risk quality change over time**, and does it track the macroeconomic conditions at the moment the loan was issued?
2. **Does the income verification control actually reduce default risk**, or is it a formality with no demonstrated effect?

The second question is deliberately written from a supervisory point of view. Not "how large is the risk", but "is the control already in place doing what it was built to do".

## Data Understanding and Preparation

- **Source:** public Lending Club dataset (Kaggle), 2,260,668 loans, June 2007 to December 2018.
- **Key characteristic:** the data is a single snapshot per loan, as of February 2019, not a monthly panel. Loan-age analysis is therefore built on a cohort approach by issue month, not a full survival curve.
- **Data problems found and handled:**
  - *Right-censoring*: recently issued loans have not had time to default. The population definition for the main trend analysis was restricted to matured loans, meaning only loans whose full term has already elapsed.
  - 3,913 rows (0.5%) were still in a non-final status despite being past maturity. These were removed from the analysis population and documented separately rather than quietly absorbed into the totals.
  - Joint applications (5.3% of the data) were excluded, because their verification structure differs from individual applications.

## Analysis Process

1. **Python** to reduce the raw 1.1 GB file down to the relevant column subset.
2. **PostgreSQL** for all cleaning logic, population definitions (matured versus censored), and aggregation. This was done at the SQL layer rather than inside the visualization tool, so that every chart reads from one consistent source of truth.
3. **Cohort methodology**: loans grouped by issue month, then default trends compared across cohorts.
4. **Controlling for confounders**: the verification comparison is stratified by risk grade (A to G), to avoid a false conclusion driven by grade already correlating with who gets verified. The pattern was then re-validated while controlling for cohort year, to confirm it is not an artifact of the data mix shifting over time.
5. **Tableau** for an interactive dashboard built in four stages: baseline, transparency about not-yet-final data, the main finding, and a drill-down that lets the reader validate the finding independently.

## Key Insights

**1. Credit risk follows the economic cycle, not only the individual borrower profile.**
Loans issued in the run-up to the 2008 financial crisis carry default rates of 20 to 26%. That falls to 10 to 11% during the 2010 to 2011 recovery, then climbs back to 13 to 15% across 2012 to 2015.

**2. The verification paradox: "verified" status correlates with higher risk, consistently across every grade from A to G.**
Loans marked *Verified* or *Source Verified* default more often than *Not Verified* loans. The pattern holds after controlling for grade and for cohort year. The most plausible reading is selection bias: verification appears to be applied reactively and selectively to applications that already looked risky, rather than evidence that the verification process itself fails causally.

## Recommendations

1. **Weight risk by the economic cycle at issuance.** Scoring models should account for macroeconomic conditions, not only the individual borrower profile.
2. **Re-audit the income verification process.** A pattern this consistent across all risk grades suggests verification is applied reactively rather than at random. This is a note for review, not proof that the system failed.
3. **Do not treat verification status as a standalone "safe" signal.** Combine it with grade and other indicators before using it in approval or pricing decisions.
4. **Further validation is needed** using underwriting process data, specifically when and why a loan was verified, to confirm this is purely a selection effect rather than a factor not captured in the data.

## Visualizations

**Scene 1. Cohort trend 2007 to 2015 (U-shaped pattern, 2008 crisis effect)**
![Scene 1](assets/scene1_tren_cohort.jpeg)

**Scene 2. Cohorts 2016 to 2018 (transparency about not-yet-final data)**
![Scene 2](assets/scene2_cohort_belum_matang.jpeg)

**Scene 3. Verification paradox heatmap (the main finding)**
![Scene 3](assets/scene3_heatmap_verifikasi.jpeg)

**Scene 4. Drill-down by year (reader-led validation of the main finding)**
![Scene 4](assets/scene4_drilldown_tahun.jpeg)

## Tech Stack

`Python` `PostgreSQL` `SQL` `Tableau`

## Repository Structure

```
├── README.md
├── sql/
│   ├── 02_postgres_schema_and_load.sql
│   ├── 03_postgres_views.sql
│   └── 04_validation_checklist.sql
├── python/
│   └── 01_reduce_columns.py
└── assets/
    └── (dashboard screenshots)
```
