-- Power BI query shape 278 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            97
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             4,966,541
-- Rows returned         51,792
-- Avg duration          905 ms
-- Power BI datasets     981c2152-e626-4c9c-a7e3-c5876773579b
-- Tables                community_salesforce.account, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  p.name AS ProviderName,
  a.id AS SF_ID,
  a.hmc_franchise_number_c AS FranchiseNumber,
  a.hmc_alternate_account_phone_1_c AS AlternativePhone1,
  a.hmc_alternate_account_phone_2_c AS AlternativePhone2
FROM main.prod_homecare_actransactional_organization.provider AS p
LEFT JOIN main.community_salesforce.account AS a
  ON a.hmc_cart_provider_id_c = p.providerid
WHERE
  p.providerorganizationid = 7
