-- Power BI query shape 592 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             41,915
-- Rows returned         39,237
-- Avg duration          365 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.opportunity
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  id,
  owner_id,
  Name,
  stage_name,
  account_id,
  hmc_franchise_c,
  CAST(close_date AS DATE) AS CloseDate,
  CAST(created_date AS DATE) AS CreatedDate
FROM main.community_salesforce.opportunity
WHERE
  created_date >= '2025'
