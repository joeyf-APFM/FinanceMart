-- Power BI query shape 150 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            358
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             159,399
-- Rows returned         261,765
-- Avg duration          742 ms
-- Power BI datasets     2cceff05-ca68-44c0-8f76-545dd698db36
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
  Month,
  MonthName,
  Year,
  WEEKOFYEAR(date) AS WeekofYear,
  MonthYearID
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date <= DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
ORDER BY
  date ASC
