-- Power BI query shape 554 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,255,694
-- Rows returned         24,151
-- Avg duration          1,127 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  psc.providerid,
  countryid
FROM main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
LEFT JOIN main.prod_homecare_actransactional_geo.postalcode_01072025 AS pc
  ON pc.code = psc.postalcode
WHERE
  psc.deleted = 0
