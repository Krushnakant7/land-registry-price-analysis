-- 04_composition_check.sql
-- Sanity check: is Monmouthshire's #1 ranking a real price move, or a
-- composition effect (e.g. a shift toward more expensive property types
-- in later quarters skewing the median upward)?
--
-- Method: break down sales by property type per quarter. If one type's
-- share of sales jumps sharply in a later quarter, that alone could
-- explain rising median price without any real appreciation.

SELECT
    DATE_TRUNC('quarter', date_of_transfer) AS sale_quarter,
    property_type,
    COUNT(*) AS num_sales,
    MEDIAN(price) AS median_price
FROM clean_sales
WHERE district = 'MONMOUTHSHIRE'
GROUP BY sale_quarter, property_type
ORDER BY sale_quarter, property_type;

-- Result: property type mix stayed roughly stable across all 4 quarters
-- (detached ~40% throughout), and prices rose within each type individually.
-- This rules out a simple composition effect -- the growth looks real.
--
-- Same spot-check pattern can be reused for any other district in the
-- top 10 by changing the WHERE clause, e.g. to check Camden or Islington's
-- Q2 spike-then-fade pattern discussed in the README.
