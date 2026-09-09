-- Power BI query shape 75 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,157
-- Distinct texts        8 (same query, different literals or projection)
-- Rows read             318,356
-- Rows returned         1,601,740
-- Avg duration          318 ms
-- Power BI datasets     b19514eb-b858-44d5-81a1-2c1a2e9f1483
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2024'
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
