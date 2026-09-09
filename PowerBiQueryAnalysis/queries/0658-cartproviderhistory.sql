-- Power BI query shape 658 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,288,445
-- Rows returned         1,288,445
-- Avg duration          3,777 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  Date,
  cph.providerid,
  cph.orderid,
  monthlycap
FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
WHERE
  date >= '2025'
  AND (
    orderstatus = 'Active' OR orderstatusreason = 'Monthly Cap Reached'
  )
