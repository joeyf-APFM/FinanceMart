-- Power BI query shape 2 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6,181
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             1,404,398
-- Rows returned         29,346,071
-- Avg duration          269 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4, 728529db-9b31-4ce3-9fd4-4fdf844d7334, 75a0183c-2c90-4d23-9c69-cdb19108448e, c65e1078-f986-4629-8d3f-50f7370b5719, da74b405-09e2-41e3-bed6-583fc3c4acae, eda315a6-a542-4102-b6ce-3551c75b1bdd, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0, fe02549c-24f9-4a63-88e9-89efbaf400ed
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
