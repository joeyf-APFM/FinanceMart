-- Power BI query shape 408 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             730
-- Rows returned         4,380
-- Avg duration          196 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
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
    ROW_NUMBER() OVER (PARTITION BY dayofweek, month ORDER BY date) AS WeekDay
  FROM prod_homecare_acreporting_reporting.dimdate
  WHERE
    year IN ('2026', '2025')
)
SELECT
  CTE.*,
  CONCAT(dayofweek, '-', Weekday) AS DayofWeekNumberMonth
FROM CTE
