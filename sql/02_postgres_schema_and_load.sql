-- =====================================================================
-- 02_postgres_schema_and_load.sql
-- =====================================================================
-- Tahap staging: muat loan_slim.csv (hasil 01_reduce_columns.py) apa
-- adanya sebagai TEXT dulu. Ini sengaja TIDAK langsung cast ke tipe
-- data final di tahap ini -- casting dilakukan di 03_postgres_views.sql
-- lewat VIEW, supaya kalau ada baris dengan format tak terduga, proses
-- import tidak gagal total (COPY akan error keras kalau tipe data
-- langsung dipaksa saat import).
-- =====================================================================

DROP TABLE IF EXISTS loan_raw;

CREATE TABLE loan_raw (
    loan_amnt            TEXT,
    term                 TEXT,
    int_rate             TEXT,
    grade                TEXT,
    sub_grade            TEXT,
    issue_d              TEXT,
    loan_status          TEXT,
    last_pymnt_d         TEXT,
    application_type     TEXT,
    verification_status  TEXT,
    purpose              TEXT,
    addr_state           TEXT
);



-- Sanity check jumlah baris setelah load (harus 2.260.668 kalau pakai
-- dataset Lending Club loan.csv full 2007-2018 yang sama):
-- SELECT COUNT(*) FROM loan_raw;
