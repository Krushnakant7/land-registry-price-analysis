-- 01_exploration.sql
-- Initial load and data quality profiling of UK Land Registry Price Paid, 2025

-- Load raw data as all-text so nothing fails on import.
-- File ships with no header row; column names supplied from Land Registry definitions.
CREATE TABLE raw_sales AS
SELECT * FROM read_csv('pp-2025.csv',
    header = false,
    all_varchar = true,
    names = ['transaction_id','price','date_of_transfer','postcode',
             'property_type','old_new','duration','paon','saon','street',
             'locality','town_city','district','county','ppd_category',
             'record_status']
);

-- Row count check
SELECT COUNT(*) FROM raw_sales;

-- Price range and central tendency
-- min £1, max £793,020,000, mean £387,536 -- large mean/median gap signals outliers
SELECT MIN(CAST(price AS BIGINT)), MAX(CAST(price AS BIGINT)), AVG(CAST(price AS BIGINT))
FROM raw_sales;

-- Problem zone counts
SELECT COUNT(*) FROM raw_sales WHERE CAST(price AS BIGINT) < 1000;        -- 507 rows
SELECT COUNT(*) FROM raw_sales WHERE CAST(price AS BIGINT) > 10000000;    -- 717 rows

-- ppd_category split: A = arm's-length market sale, B = repossession/buy-to-let/not full value
SELECT ppd_category, COUNT(*) FROM raw_sales GROUP BY ppd_category;

-- property_type split: T/S/D/F = residential, O = other (commercial/land)
SELECT property_type, COUNT(*) FROM raw_sales GROUP BY property_type ORDER BY COUNT(*) DESC;

-- Blank postcodes
SELECT COUNT(*) FROM raw_sales WHERE postcode IS NULL OR postcode = '';

-- Preview of combined filter before building the clean table
SELECT COUNT(*) FROM raw_sales
WHERE CAST(price AS BIGINT) BETWEEN 1000 AND 10000000
  AND property_type != 'O'
  AND ppd_category = 'A';
