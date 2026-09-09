-- Power BI query shape 379 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            8
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             260
-- Rows returned         520
-- Avg duration          714 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimstateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  StateProvinceID,
  CountryID,
  Iso2Code,
  Name
FROM prod_homecare_acreporting_reporting.dimstateprovince
