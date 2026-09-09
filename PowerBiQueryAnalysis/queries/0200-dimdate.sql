-- Power BI query shape 200 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            250
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             237,615
-- Rows returned         273,655
-- Avg duration          832 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  *,
  CONCAT(Monthname, ' ', year) AS MonthYear,
  DATEDIFF(DAY, CURRENT_TIMESTAMP(), date) AS Today
FROM main.prod_homecare_acreporting_reporting.dimdate
WHERE
  date >= '2025'
  AND date < DATE_ADD(YEAR, 2, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
