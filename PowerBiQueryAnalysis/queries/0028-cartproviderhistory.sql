-- Power BI query shape 28 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,418
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,279,094,624
-- Rows returned         10,156,463,777
-- Avg duration          7,624 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM prod_homecare_acreporting_reporting.cartproviderhistory
WHERE
  date >= '2025'
