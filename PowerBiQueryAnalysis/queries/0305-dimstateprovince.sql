-- Power BI query shape 305 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            57
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,470
-- Rows returned         3,705
-- Avg duration          849 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimstateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  StateProvinceID,
  Name AS StateProvince,
  Iso2Code,
  CountryID
FROM prod_homecare_acreporting_reporting.dimstateprovince
