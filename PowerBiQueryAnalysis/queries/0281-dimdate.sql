-- Power BI query shape 281 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            91
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             13,870
-- Rows returned         66,430
-- Avg duration          255 ms
-- Power BI datasets     392d03ed-c952-4264-963d-fc700b0edcda
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
  MonthYearID
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  year IN ('2026', '2025')
