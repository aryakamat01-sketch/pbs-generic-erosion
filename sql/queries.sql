-- PBS Generic Price Erosion Analysis
-- SQL implementation against SQLite (pbs.db)
-- Tables: dispensing (789,577 rows), drug_map (12,162 rows)


-- 1. Monthly aggregation --------------------------------------------------
-- One row per item code per month. Returns 195,389 rows.


SELECT
    d.ITEM_CODE,
    d.date,
    SUM(d.PRESCRIPTIONS) AS scripts,
    SUM(d.TOTAL_COST)    AS cost,
    SUM(d.TOTAL_COST) / SUM(d.PRESCRIPTIONS) AS cost_per_script,
    m.DRUG_NAME,
    m."FORM/STRENGTH" AS form_strength
FROM dispensing d
LEFT JOIN drug_map m ON d.ITEM_CODE = m.ITEM_CODE
GROUP BY d.ITEM_CODE, d.date


-- 2. Candidate selection --------------------------------------------------
-- Items present in all 48 months with >100,000 total prescriptions.
-- Returns 885 items. HAVING filters groups after aggregation.


SELECT
    ITEM_CODE,
    COUNT(DISTINCT date) AS months,
    SUM(scripts)         AS total_scripts
FROM (
    SELECT ITEM_CODE, date, SUM(PRESCRIPTIONS) AS scripts
    FROM dispensing
    GROUP BY ITEM_CODE, date
)
GROUP BY ITEM_CODE
HAVING COUNT(DISTINCT date) = 48
   AND SUM(scripts) > 100000


-- 3. Month-on-month price change ------------------------------------------
-- LAG() with PARTITION BY gives each item its previous month's price.


WITH monthly AS (
    SELECT
        ITEM_CODE,
        date,
        SUM(PRESCRIPTIONS) AS scripts,
        SUM(TOTAL_COST) / SUM(PRESCRIPTIONS) AS cost_per_script
    FROM dispensing
    GROUP BY ITEM_CODE, date
),
candidates AS (
    SELECT ITEM_CODE
    FROM monthly
    GROUP BY ITEM_CODE
    HAVING COUNT(DISTINCT date) = 48 AND SUM(scripts) > 100000
),
with_lag AS (
    SELECT
        m.ITEM_CODE,
        m.date,
        m.cost_per_script,
        LAG(m.cost_per_script) OVER (PARTITION BY m.ITEM_CODE ORDER BY m.date) AS prev_price
    FROM monthly m
    JOIN candidates c ON m.ITEM_CODE = c.ITEM_CODE
)
SELECT
    ITEM_CODE,
    date,
    cost_per_script,
    prev_price,
    (cost_per_script - prev_price) / prev_price * 100 AS pct_change
FROM with_lag
WHERE prev_price IS NOT NULL
ORDER BY pct_change
LIMIT 15


-- 4. Event identification -------------------------------------------------
-- ROW_NUMBER() ranked by pct_change ascending; rn = 1 is the steepest drop.


WITH monthly AS (
    SELECT ITEM_CODE, date,
           SUM(PRESCRIPTIONS) AS scripts,
           SUM(TOTAL_COST) / SUM(PRESCRIPTIONS) AS cost_per_script
    FROM dispensing
    GROUP BY ITEM_CODE, date
),
candidates AS (
    SELECT ITEM_CODE FROM monthly
    GROUP BY ITEM_CODE
    HAVING COUNT(DISTINCT date) = 48 AND SUM(scripts) > 100000
),
changes AS (
    SELECT m.ITEM_CODE, m.date, m.scripts, m.cost_per_script,
           (m.cost_per_script - LAG(m.cost_per_script)
                OVER (PARTITION BY m.ITEM_CODE ORDER BY m.date))
           / LAG(m.cost_per_script)
                OVER (PARTITION BY m.ITEM_CODE ORDER BY m.date) * 100 AS pct_change
    FROM monthly m
    JOIN candidates c ON m.ITEM_CODE = c.ITEM_CODE
),
events AS (
    SELECT ITEM_CODE, date AS event_date, pct_change,
           ROW_NUMBER() OVER (PARTITION BY ITEM_CODE ORDER BY pct_change) AS rn
    FROM changes
    WHERE pct_change IS NOT NULL
)
SELECT ITEM_CODE, event_date, pct_change AS event_drop
FROM events
WHERE rn = 1 AND pct_change < -15
ORDER BY pct_change
LIMIT 20


-- 5. Pre/post event windows -----------------------------------------------
-- Conditional aggregation computes four windows in one pass.
-- HAVING COUNT(*) = 24 enforces 12 months either side.


WITH monthly AS (
    SELECT ITEM_CODE, date,
           SUM(PRESCRIPTIONS) AS scripts,
           SUM(TOTAL_COST) / SUM(PRESCRIPTIONS) AS cost_per_script
    FROM dispensing
    GROUP BY ITEM_CODE, date
),
candidates AS (
    SELECT ITEM_CODE FROM monthly
    GROUP BY ITEM_CODE
    HAVING COUNT(DISTINCT date) = 48 AND SUM(scripts) > 100000
),
changes AS (
    SELECT m.ITEM_CODE, m.date,
           (m.cost_per_script - LAG(m.cost_per_script)
                OVER (PARTITION BY m.ITEM_CODE ORDER BY m.date))
           / LAG(m.cost_per_script)
                OVER (PARTITION BY m.ITEM_CODE ORDER BY m.date) * 100 AS pct_change
    FROM monthly m
    JOIN candidates c ON m.ITEM_CODE = c.ITEM_CODE
),
events AS (
    SELECT ITEM_CODE, date AS event_date,
           ROW_NUMBER() OVER (PARTITION BY ITEM_CODE ORDER BY pct_change) AS rn
    FROM changes
    WHERE pct_change IS NOT NULL AND pct_change < -15
)
SELECT
    e.ITEM_CODE,
    dm.DRUG_NAME,
    e.event_date,
    AVG(CASE WHEN m.date <  e.event_date THEN m.cost_per_script END) AS pre_price,
    AVG(CASE WHEN m.date >= e.event_date THEN m.cost_per_script END) AS post_price,
    AVG(CASE WHEN m.date <  e.event_date THEN m.scripts END)         AS pre_scripts,
    AVG(CASE WHEN m.date >= e.event_date THEN m.scripts END)         AS post_scripts
FROM events e
JOIN monthly m
  ON m.ITEM_CODE = e.ITEM_CODE
 AND m.date >= DATE(e.event_date, '-12 months')
 AND m.date <  DATE(e.event_date, '+12 months')
LEFT JOIN drug_map dm ON dm.ITEM_CODE = e.ITEM_CODE
WHERE e.rn = 1
GROUP BY e.ITEM_CODE, dm.DRUG_NAME, e.event_date
HAVING COUNT(*) = 24
ORDER BY dm.DRUG_NAME

