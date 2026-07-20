-- =========================================================
-- PROJECT: Layoffs Exploratory Data Analysis (EDA)
-- DESCRIPTION: Eksplorasi data layoffs yang sudah dibersihkan
--              (layoffs_staging2) untuk menemukan pola dan tren
-- =========================================================


-- =========================================================
-- Eksplorasi Awal
-- =========================================================

SELECT *
FROM layoffs_staging2;


-- =========================================================
-- Nilai Ekstrem: Layoff Terbesar & Persentase Terbesar
-- =========================================================

SELECT  MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- INSIGHT:
-- Layoff terbesar dalam satu kali pengumuman mencapai 12.000 karyawan
-- (Google, 2023). Nilai maksimum percentage_laid_off adalah 1 (100%),
-- artinya ada company yang melakukan PHK terhadap SELURUH karyawannya.


-- =========================================================
-- Company yang Melakukan PHK 100% (Tutup Total)
-- =========================================================

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1 
ORDER BY funds_raised_millions DESC;

-- INSIGHT:
-- Beberapa company melakukan PHK terhadap 100% karyawannya (kemungkinan
-- besar tutup/bangkrut). Britishvolt adalah yang paling mencolok --
-- perusahaan ini sempat meraih pendanaan hingga $2.4 miliar sebelum
-- akhirnya tutup total, menunjukkan bahwa besarnya funding tidak
-- menjamin keberlangsungan bisnis.


-- =========================================================
-- Company dengan Total Layoff Terbanyak
-- =========================================================

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC;

-- INSIGHT:
-- Amazon menempati posisi teratas dengan total 18.150 karyawan di-PHK
-- sepanjang periode data, diikuti Google (12.000) dan Ericsson (8.500).
-- Company-company besar/mature (bukan startup) mendominasi daftar ini,
-- menunjukkan gelombang PHK ini turut menyasar perusahaan teknologi
-- besar, bukan cuma startup yang biasanya lebih rentan.


-- =========================================================
-- Rentang Waktu Data
-- =========================================================

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- INSIGHT:
-- Data mencakup periode dari Maret 2020 hingga Maret 2023 (± 3 tahun),
-- mencakup awal pandemi COVID-19 hingga gelombang resesi tech 2022-2023.


-- =========================================================
-- Total Layoff per Industri
-- =========================================================

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry 
ORDER BY 2 DESC;

-- INSIGHT:
-- Industri Consumer mencatat total layoff tertinggi (45.182), disusul
-- Retail (43.613) dan Other (36.289). Consumer dan Retail yang sangat
-- bergantung pada belanja konsumen langsung tampak paling terdampak,
-- sementara kategori "Other" mencakup berbagai industri yang tidak
-- terklasifikasi secara spesifik dalam dataset ini.


SELECT *
FROM layoffs_staging2


SELECT *
FROM layoffs_staging2
WHERE `date` IS NULL;


-- =========================================================
-- Total Layoff per Tahun
-- =========================================================

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`) 
ORDER BY 1 DESC;

-- INSIGHT:
-- 2022 adalah tahun dengan total layoff tertinggi (160.661), diikuti
-- 2023 (125.677) meski datanya baru mencakup 3 bulan pertama (Jan-Mar).
-- 2020 mencatat 80.998 -- didorong oleh dampak awal pandemi COVID-19 --
-- sementara 2021 jauh lebih rendah (15.823), menunjukkan periode
-- pemulihan sebelum gelombang PHK kembali melonjak tajam di 2022-2023.
-- Terdapat 500 layoff dengan tanggal tidak diketahui (NULL) akibat
-- data mentah yang tidak lengkap atau format yang tidak konsisten.


-- =========================================================
-- Total Layoff per Stage Perusahaan
-- =========================================================

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage 
ORDER BY 2 DESC;

-- INSIGHT:
-- Company dengan stage "Post-IPO" (sudah go public) mencatat total
-- layoff jauh di atas kategori lain (204.132), lebih dari 5x lipat
-- dibanding stage kedua tertinggi. Ini masuk akal karena company
-- post-IPO umumnya berukuran besar dengan jumlah karyawan yang
-- jauh lebih banyak dibanding startup early-stage.


SELECT company, SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC;


-- =========================================================
-- Tren Layoff per Bulan
-- =========================================================

SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)  
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- INSIGHT:
-- Ada dua lonjakan besar yang terlihat jelas: April-Mei 2020 (26.710
-- dan 25.804 -- awal pandemi COVID-19) dan November 2022 - Februari
-- 2023 (didorong gelombang resesi tech). Puncak tertinggi terjadi di
-- Januari 2023 dengan 84.714 karyawan di-PHK dalam satu bulan saja --
-- jauh di atas bulan manapun sepanjang periode data, bahkan hampir
-- 3x lipat lonjakan awal pandemi tahun 2020.


-- =========================================================
-- Rolling Total (Kumulatif) Layoff per Bulan
-- =========================================================

WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off
,SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- INSIGHT:
-- Rolling total naik cukup tajam di awal periode (Maret-Juni 2020, dari
-- 9.628 ke 69.769) akibat guncangan awal pandemi, lalu melandai sepanjang
-- pertengahan 2020 hingga 2021 (hanya naik dari 80.998 ke 96.821 dalam
-- setahun penuh). Tren kembali menanjak mulai pertengahan 2022 dan
-- menjadi paling curam pada November 2022 - Januari 2023 -- rolling
-- total melonjak dari 193.702 menjadi 342.196 hanya dalam 3 bulan,
-- lebih dari sepertiga total keseluruhan periode data. Pola ini
-- menunjukkan gelombang PHK terbesar justru terjadi di akhir 2022
-- hingga awal 2023 (fase resesi tech), jauh melampaui skala guncangan
-- awal pandemi di tahun 2020.


SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;


-- =========================================================
-- Top 5 Company dengan Layoff Terbanyak per Tahun
-- =========================================================

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC ) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_rank
WHERE Ranking <= 5
;

-- INSIGHT:
-- - 2020: Uber memimpin (7.525), diikuti Booking.com dan Groupon --
--   didominasi sektor travel/consumer yang paling terdampak awal pandemi
-- - 2021: Bytedance memimpin (3.600), tahun dengan angka layoff paling
--   rendah secara keseluruhan (masa recovery pandemi)
-- - 2022: Meta memimpin (11.000), diikuti Amazon (10.150) dan Cisco --
--   awal mula gelombang resesi tech dimulai, didominasi big tech
-- - 2023: Google memimpin (12.000), diikuti Microsoft (10.000) dan
--   Ericsson -- company-company teknologi besar mendominasi puncak
--   gelombang PHK

-- Pola menarik: Amazon konsisten masuk top 5 di dua tahun berturut-turut
-- (2022 dan 2023), menunjukkan PHK berkelanjutan/bertahap dari
-- perusahaan tersebut, bukan satu kali kejadian besar. Selain itu,
-- terdapat dua kasus seri nilai (tie) yang ditangani DENSE_RANK --
-- Carvana & Philips sama-sama rank 5 di 2022 (4.000), dan Amazon &
-- Salesforce sama-sama rank 4 di 2023 (8.000).

-- =========================================================
-- EDA SELESAI
-- Ringkasan lengkap insight tersedia di README.md
-- =========================================================