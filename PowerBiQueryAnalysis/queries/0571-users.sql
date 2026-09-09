-- Power BI query shape 571 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             7,309,628
-- Rows returned         996
-- Avg duration          744 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_dbo.users
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  usercode
FROM main.prod_homecare_insite_dbo.users
