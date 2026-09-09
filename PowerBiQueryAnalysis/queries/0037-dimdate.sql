-- Power BI query shape 37 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,199
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,818,867
-- Rows returned         10,443,051
-- Avg duration          336 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd
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
  WeekEndDate,
  DATEDIFF(DAY, CAST(CURRENT_TIMESTAMP() AS DATE), Date) AS Today,
  CONCAT(MonthName, ' ', Year) AS MonthYear
FROM prod_homecare_acreporting_reporting.dimdate
