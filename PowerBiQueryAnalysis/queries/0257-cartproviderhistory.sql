-- Power BI query shape 257 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            136
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             514,982,318
-- Rows returned         503,608,170
-- Avg duration          21,520 ms
-- Power BI datasets     c510df23-2b0d-4820-90d4-7aa0d70d29f0
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name AS Provider,
  po.Name AS Organization,
  cph.Date,
  cph.Orderid,
  cph.OrderName,
  cph.orderstatus,
  cph.orderstatusreason
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.providerid = p.providerid
LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  ON cph.providerid = p.providerid AND cph.orderid = op.orderid
WHERE
  (
    cph.orderstatus = 'Active' OR cph.orderstatusreason = 'Monthly Cap Reached'
  )
  AND date >= '2024'
