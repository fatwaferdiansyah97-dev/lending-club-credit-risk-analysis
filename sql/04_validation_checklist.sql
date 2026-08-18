-- =====================================================================
-- 04_validation_checklist.sql
-- =====================================================================

-- Cek 1: total baris mentah
SELECT COUNT(*) FROM loan_raw;

-- Cek 2: tidak ada kegagalan parse tanggal issue_date
SELECT COUNT(*) FROM loan_clean WHERE issue_date IS NULL;

-- Cek 3: snapshot date (dipakai sebagai acuan dinamis "matured")
SELECT MAX(last_pymnt_date) FROM loan_clean;

-- Cek 4: ukuran populasi final
SELECT COUNT(*) FROM loan_matured;

SELECT COUNT(*) FROM loan_matured_anomaly;

SELECT COUNT(*) FROM loan_censored;

-- Cek 5: tren cohort tahunan, term 36 bulan 
SELECT
    EXTRACT(YEAR FROM cohort_month) AS yr,
    SUM(total_loans) AS total_loans,
    SUM(defaulted_loans) AS defaulted,
    ROUND(100.0 * SUM(defaulted_loans) / SUM(total_loans), 2) AS default_rate_pct
FROM vw_cohort_trend
WHERE term_months = 36
GROUP BY 1 ORDER BY 1;


-- Cek 6: TEMUAN UTAMA sudut pandang C -- verification status vs
-- default rate, stratifikasi by grade. 
SELECT * FROM vw_verification_effectiveness ORDER BY grade, verification_status;

-- Cek 7: kontrol confound waktu -- apakah pola di Cek 6 tetap muncul
-- kalau dikontrol per tahun cohort (bukan cuma per grade)?
SELECT * FROM vw_verification_effectiveness_by_cohort
WHERE cohort_year = 2013 AND grade = 'C'
ORDER BY verification_status;

