-- Power BI query shape 160 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            299
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             981,711,332
-- Rows returned         11,507
-- Avg duration          1,428 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  CASE WHEN CSM IS NULL THEN 'Independent' ELSE CSM END AS CSM
FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
WHERE
  Date >= '2025-02-01'
