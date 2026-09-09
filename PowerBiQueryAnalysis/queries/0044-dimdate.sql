-- Power BI query shape 44 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,985
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             223,741
-- Rows returned         1,451,316
-- Avg duration          328 ms
-- Power BI datasets     e9d48e9c-bb12-4860-b411-434978fd49fe
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  DateID,
  Date,
  DayOfYear,
  DayOfMonth,
  DayOfWeek,
  WeekDayName,
  WEEKOFYEAR(date) AS WeekofYear,
  Month,
  MonthName,
  Year,
  MonthYearID,
  CASE WHEN date >= '2025-11-01' THEN 'Post Test' ELSE 'Pre Test' END AS TestGroup
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date <= DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
ORDER BY
  date ASC
