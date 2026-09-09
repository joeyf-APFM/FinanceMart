-- Power BI query shape 453 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,618
-- Rows returned         4,000
-- Avg duration          318 ms
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
  NOT a.hmc_cart_provider_id_c IS NULL
