-- Power BI query shape 385 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             573,939
-- Rows returned         34,482
-- Avg duration          660 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.opportunity
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  o.owner_id,
  a.hmc_cart_provider_id_c AS ProviderID,
  is_closed,
  is_won,
  o.created_date,
  o.hmc_lead_source_c AS Lead_Source
FROM main.community_salesforce.opportunity AS o
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = o.account_id
WHERE
  o.created_date >= '2025-07-01'
