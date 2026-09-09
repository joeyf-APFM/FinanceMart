-- Power BI query shape 261 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            122
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             64,240
-- Rows returned         103,295
-- Avg duration          773 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  *
FROM main.prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2025'
  AND date < DATE_ADD(YEAR, 2, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
