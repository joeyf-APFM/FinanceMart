-- Power BI query shape 83 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            998
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             158,019
-- Rows returned         731,078
-- Avg duration          256 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
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
  MonthName,
  WEEKOFYEAR(date) AS WeekofYear
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2025-03-01'
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
