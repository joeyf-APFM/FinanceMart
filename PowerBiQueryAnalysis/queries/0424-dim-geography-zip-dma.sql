-- Power BI query shape 424 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             89,648
-- Rows returned         172,104
-- Avg duration          494 ms
-- Power BI datasets     none recorded
-- Tables                reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  zip,
  city_full_name,
  state_code,
  dma
FROM reporting.dim_geography_zip_dma
