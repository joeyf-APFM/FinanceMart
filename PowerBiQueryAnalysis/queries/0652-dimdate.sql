-- Power BI query shape 652 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             730
-- Rows returned         730
-- Avg duration          368 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *,
  DATE_FORMAT(date, 'MM-yyyy') AS MonthYear
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
