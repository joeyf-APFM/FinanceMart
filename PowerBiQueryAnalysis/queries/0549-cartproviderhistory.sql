-- Power BI query shape 549 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             12,165,423
-- Rows returned         1,338
-- Avg duration          891 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  cph.date,
  COUNT(DISTINCT CONCAT(cph.providerid, '-', cph.orderid)) AS ProviderOrders,
  COUNT(
    DISTINCT CASE
      WHEN cph.orderstatusreason = 'Monthly Cap Reached'
      THEN CONCAT(cph.providerid, '-', cph.orderid)
      ELSE NULL
    END
  ) AS CappedProviderOrders,
  COUNT(cph.providerid) AS Providers,
  COUNT(cph.orderid) AS Orders
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
WHERE
  date >= '2024'
  AND contracttype = 'CPL'
  AND (
    cph.orderstatus IN ('Active', 'Paused')
    OR cph.orderstatusreason = 'Monthly Cap Reached'
  )
GROUP BY
  1
