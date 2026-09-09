-- Power BI query shape 345 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            18
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             75,610
-- Rows returned         88,605
-- Avg duration          167 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYear,
    CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrderID,
    cph.orderstatus,
    cph.orderstatusreason
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    (
      cph.date = LAST_DAY(cph.date) OR cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
    )
    AND cph.date >= '2026'
)
SELECT
  CTE.MonthYear,
  CTE.ProviderOrderID,
  CTE.OrderStatus,
  CTE.OrderStatusReason,
  CASE
    WHEN (
      cte.orderstatusreason = 'Monthly Cap Reached'
      OR cte.orderstatus IN ('Active', 'Paused')
    )
    THEN 'Active+'
    WHEN cte.orderstatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status
FROM CTE
