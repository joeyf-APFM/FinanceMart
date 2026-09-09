-- Power BI query shape 147 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            373
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             16,315
-- Rows returned         24,245
-- Avg duration          640 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.dimstateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  StateProvinceID,
  CountryID,
  Iso2Code,
  Name
FROM prod_homecare_acreporting_reporting.dimstateprovince
