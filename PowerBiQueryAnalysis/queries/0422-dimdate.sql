-- Power BI query shape 422 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,460
-- Rows returned         3,650
-- Avg duration          139 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *,
  DATE_FORMAT(date, 'MM-yyyy') AS MonthYearCharge,
  DATE_FORMAT(DATE_ADD(MONTH, -3, DATE_TRUNC('MONTH', date)), 'MMMM') AS 3Monthago,
  CAST(DATE_ADD(MONTH, -3, DATE_TRUNC('MONTH', date)) AS DATE) AS 3MonthagoDate
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
