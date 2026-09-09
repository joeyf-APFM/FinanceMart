-- Power BI query shape 283 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            87
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             4,586,039
-- Rows returned         300,515
-- Avg duration          2,163 ms
-- Power BI datasets     eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                community_salesforce.account, community_salesforce.user, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  a.hmc_cart_provider_id_c AS ProviderID,
  a.id AS SF_AccountID,
  u.name AS CSM,
  p.name AS ProviderName,
  po.name AS Org
FROM main.community_salesforce.account AS a
LEFT JOIN main.community_salesforce.user AS u
  ON u.id = a.hmc_csm_assignee_c
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = a.hmc_cart_provider_id_c
LEFT JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  NOT a.hmc_cart_provider_id_c IS NULL AND NOT u.name IS NULL
