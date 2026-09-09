-- Power BI query shape 64 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,474
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             3,560,084,076
-- Rows returned         53,976,110
-- Avg duration          1,472 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  psc.PostalCode,
  COUNT(DISTINCT cph.ProviderID) AS CPL_Providers
FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
LEFT JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.ProviderID = cph.ProviderID
WHERE
  Date = CAST(CURRENT_TIMESTAMP() AS DATE)
  AND ContractType = 'CPL'
  AND (
    OrderStatus IN ('Active') OR OrderStatusReason = 'Monthly Cap Reached'
  )
GROUP BY
  psc.PostalCode
