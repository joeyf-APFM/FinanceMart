-- Power BI query shape 279 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            94
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             14,148,365
-- Rows returned         425,153
-- Avg duration          1,024 ms
-- Power BI datasets     981c2152-e626-4c9c-a7e3-c5876773579b
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  cph.date,
  cph.providerid,
  cph.orderid,
  CASE WHEN cph.monthlycap IS NULL THEN 'Unlimited' ELSE cph.monthlycap END AS MonthlyCap
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cph.providerid
WHERE
  (
    cph.date = LAST_DAY(cph.date) OR cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
  )
  AND cph.date >= '2025'
  AND cph.orderid <> 3265
  AND p.providerorganizationid = 7
  AND cph.contracttype = 'CPL'
  AND cph.contracttype <> 'Onboarding'
