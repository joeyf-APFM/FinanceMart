-- Power BI query shape 205 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            243
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             11,625,891
-- Rows returned         11,602,557
-- Avg duration          904 ms
-- Power BI datasets     da74b405-09e2-41e3-bed6-583fc3c4acae
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  p.name AS Provider,
  po.name AS Org
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
