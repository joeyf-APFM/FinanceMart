-- Power BI query shape 231 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             66,108,471
-- Rows returned         120,197,220
-- Avg duration          1,515 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.factproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM prod_homecare_acreporting_reporting.factproviderhistory
WHERE
  Date <= '2022-10-31'
