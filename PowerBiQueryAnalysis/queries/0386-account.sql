-- Power BI query shape 386 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             909,350
-- Rows returned         76,433
-- Avg duration          534 ms
-- Power BI datasets     none recorded
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
  o.hmc_hold_lead_volume_sold_c AS LeadVolumeSold,
  a.hmc_cart_provider_id_c AS ProviderID,
  a.name AS AccountName,
  a.id AS SFAccountID
FROM main.community_salesforce.opportunity AS o
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = o.account_id
WHERE
  close_date >= '2025-07-01'
