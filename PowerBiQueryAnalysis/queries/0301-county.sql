-- Power BI query shape 301 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             132,920
-- Rows returned         195,480
-- Avg duration          964 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.county, prod_homecare_actransactional_geo.stateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CountyID,
  CONCAT(cty.Name, ', ', sp.Iso2Code) AS County,
  sp.Iso2Code
FROM prod_homecare_actransactional_geo.county AS cty
LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
  ON cty.StateProvinceID = sp.StateProvinceID
