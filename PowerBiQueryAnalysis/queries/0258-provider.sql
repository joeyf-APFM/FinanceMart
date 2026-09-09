-- Power BI query shape 258 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            136
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             305,682,083
-- Rows returned         305,221,457
-- Avg duration          9,482 ms
-- Power BI datasets     c510df23-2b0d-4820-90d4-7aa0d70d29f0
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name,
  po.Name AS Org,
  TRIM(psc.postalcode) AS postalcode
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
LEFT JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.providerid = p.providerid
WHERE
  psc.deleted = 0
