-- Power BI query shape 202 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            247
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             86,414,615
-- Rows returned         17,883,593
-- Avg duration          1,670 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                community_salesforce.account, community_salesforce.opportunity
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  o.id AS SF_OpportunityId,
  CAST(o.created_date AS DATE) AS CreatedDate,
  CAST(o.close_date AS DATE) AS ClosedDate,
  o.is_closed,
  o.is_won,
  o.owner_id,
  o.name AS OpportunityName,
  a.hmc_cart_provider_id_c AS ProviderID,
  a.name AS AccountName,
  o.stage_name,
  a.id AS SFAccountID,
  a.hmc_lead_volume_sold_c AS LeadVolumeSold
FROM main.community_salesforce.opportunity AS o
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = o.account_id
WHERE
  close_date >= '2025-07-01'
