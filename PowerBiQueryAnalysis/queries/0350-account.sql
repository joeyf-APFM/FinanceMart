-- Power BI query shape 350 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            17
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             9,375
-- Rows returned         19,545
-- Avg duration          305 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  a.hmc_cart_provider_id_c AS ProviderID,
  a.id AS SF_AccountID,
  u.name AS CSM
FROM main.community_salesforce.account AS a
LEFT JOIN main.community_salesforce.user AS u
  ON u.id = a.hmc_csm_assignee_c
WHERE
  NOT a.hmc_cart_provider_id_c IS NULL AND NOT u.name IS NULL
