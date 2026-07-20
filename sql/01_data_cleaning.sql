-- =========================================================
-- PROJECT: Layoffs Data Cleaning
-- DESCRIPTION: Membersihkan raw data layoffs menggunakan MySQL
-- STEPS:
--   1. Remove Duplicates
--   2. Standardize the Data
--   3. Handle Null / Blank Values
--   4. Remove Unnecessary Rows / Columns
-- =========================================================


-- =========================================================
-- STEP 0: Eksplorasi Awal
-- =========================================================

SELECT *
FROM layoffs;


-- =========================================================
-- Membuat tabel staging (copy dari raw table)
-- agar raw data tetap aman/tidak diubah langsung
-- =========================================================

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;


-- =========================================================
-- STEP 1: Remove Duplicates
-- =========================================================

-- Cek duplikat menggunakan ROW_NUMBER() dengan PARTITION BY
-- pada kolom-kolom yang relevan
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, industry, total_laid_off,
                     percentage_laid_off, `date`
    ) AS row_num
FROM layoffs_staging;

-- Cek ulang dengan partisi kolom yang lebih lengkap
-- untuk memastikan baris benar-benar duplikat penuh
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off,
                         percentage_laid_off, `date`, stage, country,
                         funds_raised_millions
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Contoh pengecekan manual salah satu company
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Membuat tabel staging2 dengan tambahan kolom row_num
-- agar data duplikat bisa dihapus dengan mudah (DELETE tidak bisa
-- langsung dipakai bersama window function/CTE di MySQL)
CREATE TABLE `layoffs_staging2` (
    `company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text,
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country,
                     funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

-- Hapus baris duplikat (row_num > 1 berarti duplikat)
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- =========================================================
-- STEP 2: Standardize the Data
-- =========================================================

-- Menghapus whitespace di awal/akhir nama company
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Cek nilai unik pada kolom industry untuk menemukan inkonsistensi
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Menyeragamkan semua variasi 'Crypto%' (misal: 'Crypto', 'Crypto Currency')
-- menjadi satu nilai standar: 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Cek nilai unik pada kolom country, sekaligus preview hasil TRIM
-- untuk menghapus tanda titik di akhir (misal: 'United States.')
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Konversi kolom date dari text menjadi format DATE yang valid
SELECT `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- Mengubah tipe data kolom date dari TEXT menjadi DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- =========================================================
-- STEP 3: Handle Null / Blank Values
-- =========================================================

-- Cek baris yang total_laid_off dan percentage_laid_off
-- keduanya kosong (kandidat untuk dihapus nanti)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Menyeragamkan blank string ('') menjadi NULL agar konsisten
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- Contoh pengecekan manual salah satu company
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Mencari baris dengan industry kosong yang bisa diisi
-- berdasarkan data company yang sama pada baris lain
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Mengisi nilai industry yang NULL berdasarkan
-- data company yang sama pada baris lain
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;


-- =========================================================
-- STEP 4: Remove Unnecessary Rows / Columns
-- =========================================================

-- Baris tanpa data total_laid_off maupun percentage_laid_off
-- dianggap tidak informatif untuk analisis, sehingga dihapus
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Menghapus kolom row_num karena sudah tidak diperlukan
-- setelah proses penghapusan duplikat selesai
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- =========================================================
-- DATA CLEANING SELESAI
-- Tabel layoffs_staging2 siap digunakan untuk exploratory
-- data analysis (EDA)
-- =========================================================