-- Power BI query shape 323 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            30
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             97,334
-- Rows returned         92,248
-- Avg duration          692 ms
-- Power BI datasets     6f367367-19b7-4314-b324-b8f6a041aa2e
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name AS ProviderName,
  po.Name AS Org,
  CASE
    WHEN LOWER(p.name) LIKE 'housework%' OR p.providerorganizationid IN (122, 128)
    THEN 'Pilot'
    ELSE 'Main'
  END AS group
FROM main.prod_homecare_actransactional_organization.provider AS p
JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  p.providerorganizationid IN (1, 2, 3, 71, 101, 112, 117, 123, 122, 128)
  OR LOWER(p.name) LIKE 'housework%'
