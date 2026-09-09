-- Power BI query shape 26 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,424
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,595,611,148
-- Rows returned         2,653,168,148
-- Avg duration          3,839 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_billing.homecarecharge
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *
FROM main.prod_homecare_actransactional_billing.homecarecharge
WHERE
  createdon >= '2025'
