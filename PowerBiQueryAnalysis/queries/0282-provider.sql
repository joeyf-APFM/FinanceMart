-- Power BI query shape 282 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            89
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             199,125
-- Rows returned         214,262
-- Avg duration          943 ms
-- Power BI datasets     6f367367-19b7-4314-b324-b8f6a041aa2e
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name AS ProviderName,
  po.Name AS Org
FROM main.prod_homecare_actransactional_organization.provider AS p
JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  p.providerorganizationid IN (1, 2, 3, 71, 101, 112, 117, 123)
