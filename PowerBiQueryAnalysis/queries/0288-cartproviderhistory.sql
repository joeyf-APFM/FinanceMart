-- Power BI query shape 288 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            77
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,186,706
-- Rows returned         5,711,447
-- Avg duration          315 ms
-- Power BI datasets     392d03ed-c952-4264-963d-fc700b0edcda
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
    WHEN cte.orderstatus = 'Completed'
    THEN 'Completed'
    ELSE 'Inactive'
  END AS Status
FROM CTE
