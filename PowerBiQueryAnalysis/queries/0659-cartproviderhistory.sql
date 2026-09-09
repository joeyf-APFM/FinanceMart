-- Power BI query shape 659 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,267,167
-- Rows returned         1,000
-- Avg duration          2,451 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  cph.date,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
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
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cph.providerid
WHERE
  date >= '2024'
  AND contracttype = 'CPL'
  AND (
    cph.orderstatus IN ('Active', 'Paused')
    OR cph.orderstatusreason = 'Monthly Cap Reached'
  )
GROUP BY
  1,
  2
