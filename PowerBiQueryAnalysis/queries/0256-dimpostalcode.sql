-- Power BI query shape 256 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            136
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             7,586,928
-- Rows returned         5,905,936
-- Avg duration          2,038 ms
-- Power BI datasets     c510df23-2b0d-4820-90d4-7aa0d70d29f0
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimstateprovince, prod_homecare_actransactional_geo.city
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  code AS postalcode,
  c.name AS City,
  sp.name AS State
FROM prod_homecare_acreporting_reporting.dimpostalcode AS pc
LEFT JOIN prod_homecare_acreporting_reporting.dimstateprovince AS sp
  ON pc.stateprovinceid = sp.stateprovinceid
LEFT JOIN prod_homecare_actransactional_geo.city AS c
  ON c.cityid = pc.cityid
WHERE
  pc.countryid = 1
