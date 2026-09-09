-- Power BI query shape 570 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,190
-- Rows returned         1,460
-- Avg duration          38,198 ms
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
    CASE
      WHEN DayOfWeek = 2
      THEN Date
      WHEN DayOfWeek > 2
      THEN DATE_ADD(DAY, 2 - DayOfWeek, Date)
      ELSE DATE_ADD(DAY, -6, Date)
    END AS WeekStart,
    DayOfYear,
    DayOfMonth,
    DayOfWeek,
    WeekDayName,
    Month,
    MonthName,
    Year,
    YEAR(CURRENT_TIMESTAMP()) AS ModYear,
    CONCAT(MonthName, ' ', YEAR(CURRENT_TIMESTAMP())) AS ModMonthYear,
    CONCAT(MonthName, ' ', Year) AS MonthYear,
    MonthYearID
  FROM prod_homecare_acreporting_reporting.dimdate
  WHERE
    DateID BETWEEN CAST(YEAR(DATE_ADD(YEAR, -1, CURRENT_TIMESTAMP())) * 10000 AS DECIMAL) AND CAST(YEAR(DATE_ADD(YEAR, 1, CURRENT_TIMESTAMP())) * 10000 AS DECIMAL)
)
SELECT
  CTE.DateID,
  CTE.Date,
  CASE
    WHEN CTE.Year = YEAR(DATE_ADD(YEAR, -1, CURRENT_TIMESTAMP()))
    THEN DATE_ADD(YEAR, 1, CTE.Date)
    ELSE CTE.Date
  END AS ModDate,
  CTE.WeekStart,
  COALESCE(cte2.WeekStart, CTE.WeekStart) AS ModWeekStart,
  CTE.DayOfYear,
  CTE.DayOfMonth,
  CTE.DayOfWeek,
  CTE.WeekDayName,
  CTE.Month,
  CTE.MonthName,
  CTE.Year,
  CTE.ModYear,
  CTE.ModMonthYear,
  CTE.MonthYear,
  CTE.MonthYearID,
  DATEDIFF(DAY, CURRENT_TIMESTAMP(), cte.date)
FROM CTE
LEFT JOIN CTE AS cte2
  ON CTE.DayOfYear = cte2.DayOfYear
  AND cte2.Year = YEAR(DATE_ADD(YEAR, -1, CURRENT_TIMESTAMP()))
  AND CTE.Year = YEAR(CURRENT_TIMESTAMP())
