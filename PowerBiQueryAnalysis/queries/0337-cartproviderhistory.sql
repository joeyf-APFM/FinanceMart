-- Power BI query shape 337 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            24
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             36,781,099
-- Rows returned         34,014,216
-- Avg duration          7,936 ms
-- Power BI datasets     eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  cph.providerid,
  cph.orderid,
  cph.orderstatus,
  cph.orderstatusreason,
  cph.date,
  CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrderID,
  p.providerorganizationid,
  CASE
    WHEN orderstatusreason = 'Monthly Cap Reached' OR orderstatus IN ('Active', 'Paused')
    THEN 'Active+'
    WHEN orderstatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON cph.providerid = p.providerid
WHERE
  cph.date >= DATE_TRUNC('YEAR', CURRENT_TIMESTAMP())
  AND cph.contracttype IN ('CPA', 'CPL')
  AND cph.orderstatus <> 'Onboarding'
ORDER BY
  date ASC
