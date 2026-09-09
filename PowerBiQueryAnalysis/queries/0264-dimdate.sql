-- Power BI query shape 264 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            108
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             61,234
-- Rows returned         61,234
-- Avg duration          317 ms
-- Power BI datasets     981c2152-e626-4c9c-a7e3-c5876773579b
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
  DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()),
  DATE_FORMAT(date, 'MM-yyyy') AS DateC
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= CAST(DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP())) AS DATE)
  AND date <= CURRENT_TIMESTAMP()
