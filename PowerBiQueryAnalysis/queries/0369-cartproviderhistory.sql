-- Power BI query shape 369 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            9
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,653,116
-- Rows returned         1,645,597
-- Avg duration          200 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  cph.providerid,
  cph.orderid,
  CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrderID,
  cph.orderstatus,
  cph.orderstatusreason,
  cph.date,
  CASE
    WHEN orderstatusreason = 'Monthly Cap Reached' OR orderstatus IN ('Active', 'Paused')
    THEN 'Active+'
    WHEN orderstatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
WHERE
  cph.date >= DATE_TRUNC('YEAR', CURRENT_TIMESTAMP())
ORDER BY
  date ASC
