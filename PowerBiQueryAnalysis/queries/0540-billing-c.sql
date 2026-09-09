-- Power BI query shape 540 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             26,416
-- Rows returned         23,320
-- Avg duration          709 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.billing_c
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  id,
  owner_id,
  Name,
  CAST(created_date AS DATE) AS CreatedDate,
  hmc_balance_c,
  hmc_provider_account_c
FROM main.community_salesforce.billing_c
