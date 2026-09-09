-- Power BI query shape 100 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            858
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             41,368,569
-- Rows returned         41,648,645
-- Avg duration          1,210 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, a16a1e37-9a12-408d-ad05-9ea2571cb037, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Indpendent' ELSE 'Franchise' END AS OrgType,
  po.name
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
