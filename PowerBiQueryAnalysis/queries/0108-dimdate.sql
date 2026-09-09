-- Power BI query shape 108 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            598
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             170,937
-- Rows returned         873,678
-- Avg duration          270 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  Year IN (2022, 2023, 2024, 2025)
