-- Power BI query shape 107 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            606
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             219,430
-- Rows returned         535,840
-- Avg duration          204 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2024' AND date <= '2026'
