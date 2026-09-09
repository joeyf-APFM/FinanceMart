-- Power BI query shape 201 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            250
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             24,090
-- Rows returned         182,500
-- Avg duration          214 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *,
  DATE_FORMAT(date, 'MM-yyyy') AS MonthYearCharge,
  DATE_FORMAT(DATE_ADD(MONTH, -3, DATE_TRUNC('MONTH', date)), 'MMMM') AS 3Monthago,
  CAST(DATE_ADD(MONTH, -3, date) AS DATE) AS 3MonthagoDate
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
