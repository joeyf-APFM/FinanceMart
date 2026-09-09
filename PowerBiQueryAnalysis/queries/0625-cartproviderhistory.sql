-- Power BI query shape 625 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             464
-- Rows returned         15
-- Avg duration          739 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name,
  po.name AS Organization,
  p.orgid,
  cph.orderid,
  CASE
    WHEN NOT cph.orderid IS NULL AND cph.monthlycap IS NULL
    THEN 'Unlimited'
    ELSE cph.monthlycap
  END AS MonthlyCap
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
  ON p.ProviderID = r.ProviderID
LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  ON cph.providerid = p.providerid
WHERE
  r.ReferredOn >= '2023-01-01'
  AND NOT r.ProviderID IS NULL
  AND /* and cph.date = date(getdate()) */ p.providerid = 32209
ORDER BY
  p.providerid
