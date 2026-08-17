-- 02_clean_table.sql
-- Build the cleaned sales table using exclusion rules decided in 01_exploration.sql
--
-- Rules: ppd_category = 'A' only (arm's-length market sales)
--        property_type != 'O' (residential only)
--        price between £1,000 and £10,000,000
--        non-blank postcode

CREATE TABLE clean_sales AS
SELECT
    transaction_id,
    CAST(price AS BIGINT) AS price,
    CAST(date_of_transfer AS DATE) AS date_of_transfer,
    postcode,
    property_type,
    old_new,
    duration,
    town_city,
    district,
    county
FROM raw_sales
WHERE ppd_category = 'A'
  AND property_type != 'O'
  AND CAST(price AS BIGINT) BETWEEN 1000 AND 10000000
  AND postcode IS NOT NULL AND postcode != '';

-- Verify: expect ~778,857 rows
SELECT COUNT(*) FROM clean_sales;
