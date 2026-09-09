-- Power BI query shape 55 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,714
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             153,300
-- Rows returned         1,251,220
-- Avg duration          230 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *,
  DATE_FORMAT(date, 'MM-yyyy') AS MonthYearCharge
FROM prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= DATE_ADD(YEAR, -1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
  AND date < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
