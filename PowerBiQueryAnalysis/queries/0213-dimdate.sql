-- Power BI query shape 213 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             168,637
-- Rows returned         168,637
-- Avg duration          694 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, 36a8e73a-5aae-46e5-a621-b847af424af7
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
  Quarter,
  MonthYearID,
  WeekStartDate,
  WeekEndDate
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= DATE_ADD(MONTH, -3, CURRENT_TIMESTAMP())
