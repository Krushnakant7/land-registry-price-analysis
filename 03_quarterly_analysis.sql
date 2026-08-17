-- 03_quarterly_analysis.sql
-- Main analysis: which districts had the strongest quarterly price growth in 2025?
--
-- Two earlier attempts (monthly, arithmetic mean; monthly, geometric mean with a
-- 30 sales/month floor) both surfaced small, low-volume districts whose apparent
-- growth was a sample-size artefact rather than a real market signal -- see README.
-- This version aggregates to quarters and raises the volume floor to fix that.
--
-- Growth is computed as a geometric mean of quarter-over-quarter price ratios,
-- not an arithmetic average of % changes -- arithmetic mean overstates growth on
-- a volatile series (e.g. -40% then +46% averages to +3% arithmetically, but is
-- ~0% real change). Geometric mean correctly accounts for compounding.

CREATE TABLE tableau_export_v3 AS
WITH quarterly AS (
    SELECT
        district,
        DATE_TRUNC('quarter', date_of_transfer) AS sale_quarter,
        MEDIAN(price) AS median_price,
        COUNT(*) AS num_sales
    FROM clean_sales
    GROUP BY district, sale_quarter
),
-- Volume floor: at least 100 sales in the quarter to qualify
qualified_district_quarters AS (
    SELECT district, sale_quarter, median_price, num_sales
    FROM quarterly
    WHERE num_sales >= 100
),
-- Require all 4 quarters to qualify, not just some
districts_with_full_year AS (
    SELECT district
    FROM qualified_district_quarters
    GROUP BY district
    HAVING COUNT(*) = 4
),
qualified AS (
    SELECT q.*
    FROM qualified_district_quarters q
    JOIN districts_with_full_year d ON q.district = d.district
),
-- Q1 baseline for indexing (Q1 2025 = 100)
q1_price AS (
    SELECT district, median_price AS q1_price
    FROM qualified
    WHERE sale_quarter = '2025-01-01'
),
with_change AS (
    SELECT
        q.district,
        q.sale_quarter,
        q.median_price,
        q.num_sales,
        LAG(q.median_price) OVER (PARTITION BY q.district ORDER BY q.sale_quarter) AS prev_quarter_price
    FROM qualified q
),
growth_ratios AS (
    SELECT district, median_price / prev_quarter_price AS quarter_ratio
    FROM with_change
    WHERE prev_quarter_price IS NOT NULL
),
-- Geometric mean of quarter-over-quarter ratios, annualised to a quarterly rate
ranking AS (
    SELECT
        district,
        ROUND((POWER(EXP(SUM(LN(quarter_ratio))), 1.0/3) - 1) * 100, 2) AS geometric_avg_quarterly_pct_change
    FROM growth_ratios
    GROUP BY district
)
SELECT
    q.district,
    q.sale_quarter,
    q.median_price,
    q.num_sales,
    ROUND(q.median_price / j.q1_price * 100, 2) AS price_index_q100,
    r.geometric_avg_quarterly_pct_change
FROM qualified q
JOIN q1_price j ON q.district = j.district
JOIN ranking r ON q.district = r.district
ORDER BY r.geometric_avg_quarterly_pct_change DESC, q.sale_quarter;

-- Sanity checks used before trusting this result:

-- 1. Confirm every surviving district has exactly 4 quarters (no partial years)
SELECT COUNT(*) AS districts, num_quarters FROM (
    SELECT district, COUNT(*) AS num_quarters
    FROM tableau_export_v3
    GROUP BY district
) GROUP BY num_quarters;

-- 2. Full distribution -- this is the basis for the "most districts fell" headline
SELECT
    MIN(geometric_avg_quarterly_pct_change) AS min_growth,
    MEDIAN(geometric_avg_quarterly_pct_change) AS median_growth,
    MAX(geometric_avg_quarterly_pct_change) AS max_growth,
    AVG(geometric_avg_quarterly_pct_change) AS mean_growth,
    COUNT(DISTINCT district) AS num_districts
FROM tableau_export_v3;
