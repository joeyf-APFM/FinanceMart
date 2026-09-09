-- Power BI query shape 520 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,247,876
-- Rows returned         1,334
-- Avg duration          940 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.date,
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYearID,
    CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrders,
    COUNT(DISTINCT cph.date) AS Days
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    date >= '2024'
    AND cph.contracttype = 'CPL'
    AND cph.orderstatusreason = 'Monthly Cap Reached'
  GROUP BY
    1,
    2,
    3
), CTE1 AS (
  SELECT DISTINCT
    providerorders,
    SUM(days) OVER (PARTITION BY MonthYearID, providerorders ORDER BY date) AS days,
    date,
    monthyearid
  FROM CTE
  GROUP BY
    date,
    monthyearid,
    days,
    providerorders
)
SELECT
  Date,
  COUNT(DISTINCT providerorders) AS ProviderOrders,
  SUM(days),
  monthyearid
FROM CTE1
GROUP BY
  date,
  monthyearid
