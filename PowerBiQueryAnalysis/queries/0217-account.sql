-- Power BI query shape 217 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            227
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             61,640,270
-- Rows returned         9,389,239
-- Avg duration          2,024 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
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
  O.id,
  o.created_date,
  o.hmc_lead_source_c AS Lead_Source
FROM main.community_salesforce.opportunity AS o
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = o.account_id
WHERE
  o.created_date >= '2025-07-01'
