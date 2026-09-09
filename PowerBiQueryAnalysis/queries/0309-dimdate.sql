-- Power BI query shape 309 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            45
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             22,661
-- Rows returned         32,895
-- Avg duration          743 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  DateID,
  DayofWeek,
  DayofMonth,
  MonthYearID,
  Date,
  Month,
  Year,
  DayofYear,
  MonthName
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2024'
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
