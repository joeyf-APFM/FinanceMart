-- Power BI query shape 253 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            141
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             81,986
-- Rows returned         81,986
-- Avg duration          693 ms
-- Power BI datasets     6f367367-19b7-4314-b324-b8f6a041aa2e, c510df23-2b0d-4820-90d4-7aa0d70d29f0
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
  CONCAT('Q', quarter, ' ', year) AS Quarter
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2025' AND date <= CURRENT_TIMESTAMP()
