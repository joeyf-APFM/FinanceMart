-- Power BI query shape 157 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            304
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             458,041
-- Rows returned         1,394,959
-- Avg duration          722 ms
-- Power BI datasets     c38af845-cf82-47a4-9373-12845eb51d16
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
  MonthYearID,
  DATE_FORMAT(date, 'MM-yyyy') AS DateC
FROM prod_homecare_acreporting_reporting.dimdate
