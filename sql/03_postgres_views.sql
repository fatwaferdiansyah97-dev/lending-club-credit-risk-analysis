-- =====================================================================
-- 03_postgres_views.sql
-- =====================================================================
-- Semua logika filtering & agregasi dikerjakan di sini, BUKAN di
-- Tableau -- Tableau nanti hanya perlu connect ke view-view di bawah 
-- sini dan menampilkan agregat yang sudah pasti benar.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1: loan_clean -- casting tipe data + kolom turunan dasar
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS loan_clean CASCADE;

CREATE VIEW loan_clean AS
SELECT
    loan_amnt::numeric                                   AS loan_amnt,
    int_rate::numeric                                    AS int_rate,
    grade,
    sub_grade,
    purpose,
    addr_state,
    application_type,
    verification_status,
    to_date(issue_d, 'Mon-YYYY')                         AS issue_date,
   
    CASE WHEN TRIM(term) LIKE '36%' THEN 36 ELSE 60 END  AS term_months,
    to_date(last_pymnt_d, 'Mon-YYYY')                    AS last_pymnt_date,
    loan_status,
  
    CASE WHEN loan_status IN (
            'Fully Paid',
            'Charged Off',
            'Default',
            'Does not meet the credit policy. Status:Fully Paid',
            'Does not meet the credit policy. Status:Charged Off'
         ) THEN TRUE ELSE FALSE END                      AS is_resolved,
    CASE WHEN loan_status IN (
            'Charged Off',
            'Default',
            'Does not meet the credit policy. Status:Charged Off'
         ) THEN TRUE ELSE FALSE END                      AS is_default,
    to_date(issue_d, 'Mon-YYYY')
        + (CASE WHEN TRIM(term) LIKE '36%' THEN 36 ELSE 60 END
           || ' months')::interval                       AS matured_date
FROM loan_raw;


-- ---------------------------------------------------------------------
-- STEP 2: loan_matured -- populasi final untuk analisis cohort & risk
-- ---------------------------------------------------------------------
-- Definisi "matured" di sini SENGAJA gabungan dua syarat, bukan cuma
-- satu:
--   (a) tanggal jatuh tempo (issue_date + term) sudah lewat tanggal
--       snapshot data terbaru -- supaya cohort baru yang belum sempat
--       gagal bayar tidak dihitung seolah "aman" (right-censoring bias)
--   (b) loan_status sudah resolved (Fully Paid / Charged Off / dst)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS loan_matured CASCADE;

CREATE VIEW loan_matured AS
SELECT lc.*
FROM loan_clean lc
CROSS JOIN (SELECT MAX(last_pymnt_date) AS snapshot_date FROM loan_clean) snap
WHERE lc.matured_date <= snap.snapshot_date
  AND lc.application_type = 'Individual'
  AND lc.is_resolved = TRUE;


DROP VIEW IF EXISTS loan_matured_anomaly CASCADE;

CREATE VIEW loan_matured_anomaly AS
SELECT lc.*
FROM loan_clean lc
CROSS JOIN (SELECT MAX(last_pymnt_date) AS snapshot_date FROM loan_clean) snap
WHERE lc.matured_date <= snap.snapshot_date
  AND lc.application_type = 'Individual'
  AND lc.is_resolved = FALSE;


-- ---------------------------------------------------------------------
-- STEP 3: loan_censored -- cohort yang BELUM matang (masih berjalan)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS loan_censored CASCADE;

CREATE VIEW loan_censored AS
SELECT lc.*
FROM loan_clean lc
CROSS JOIN (SELECT MAX(last_pymnt_date) AS snapshot_date FROM loan_clean) snap
WHERE lc.matured_date > snap.snapshot_date
  AND lc.application_type = 'Individual';


-- ---------------------------------------------------------------------
-- STEP 4: vw_cohort_trend -- Sudut Pandang A (Vintage/Cohort Analysis)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_cohort_trend CASCADE;

CREATE VIEW vw_cohort_trend AS
SELECT
    date_trunc('month', issue_date)::date            AS cohort_month,
    term_months,
    COUNT(*)                                         AS total_loans,
    SUM(CASE WHEN is_default THEN 1 ELSE 0 END)      AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN is_default THEN 1 ELSE 0 END)
          / COUNT(*), 2)                             AS default_rate_pct,
    -- proksi lama bertahan sebelum gagal bayar (BUKAN tanggal charge-off
    -- resmi -- dataset tidak punya kolom itu). Dihitung hanya dari
    -- pinjaman yang default, pakai selisih last_pymnt_date - issue_date.
    ROUND(AVG(
        CASE WHEN is_default THEN
            (EXTRACT(YEAR FROM last_pymnt_date) * 12 + EXTRACT(MONTH FROM last_pymnt_date))
          - (EXTRACT(YEAR FROM issue_date) * 12 + EXTRACT(MONTH FROM issue_date))
        END
    ), 1)                                             AS avg_months_to_default_proxy
FROM loan_matured
GROUP BY 1, 2;


-- ---------------------------------------------------------------------
-- STEP 5: vw_cohort_trend_censored -- cohort baru, ditandai interim
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_cohort_trend_censored CASCADE;

CREATE VIEW vw_cohort_trend_censored AS
SELECT
    date_trunc('month', issue_date)::date            AS cohort_month,
    term_months,
    COUNT(*)                                         AS total_loans,
    SUM(CASE WHEN is_default THEN 1 ELSE 0 END)      AS defaulted_so_far,
    ROUND(100.0 * SUM(CASE WHEN is_default THEN 1 ELSE 0 END)
          / COUNT(*), 2)                             AS interim_default_rate_pct
FROM loan_censored
GROUP BY 1, 2;


-- ---------------------------------------------------------------------
-- STEP 6: vw_verification_effectiveness -- Sudut Pandang C
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_verification_effectiveness CASCADE;

CREATE VIEW vw_verification_effectiveness AS
SELECT
    grade,
    verification_status,
    COUNT(*)                                         AS total_loans,
    SUM(CASE WHEN is_default THEN 1 ELSE 0 END)      AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN is_default THEN 1 ELSE 0 END)
          / COUNT(*), 2)                             AS default_rate_pct
FROM loan_matured
GROUP BY 1, 2;


-- ---------------------------------------------------------------------
-- STEP 7: vw_verification_effectiveness_by_cohort -- kontrol tambahan
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_verification_effectiveness_by_cohort CASCADE;

CREATE VIEW vw_verification_effectiveness_by_cohort AS
SELECT
    EXTRACT(YEAR FROM issue_date)::int               AS cohort_year,
    grade,
    verification_status,
    COUNT(*)                                         AS total_loans,
    SUM(CASE WHEN is_default THEN 1 ELSE 0 END)      AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN is_default THEN 1 ELSE 0 END)
          / COUNT(*), 2)                             AS default_rate_pct
FROM loan_matured
GROUP BY 1, 2, 3;
