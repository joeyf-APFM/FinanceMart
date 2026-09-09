-- Power BI query shape 153 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            305
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             16,010,755
-- Rows returned         122,799
-- Avg duration          2,064 ms
-- Power BI datasets     c38af845-cf82-47a4-9373-12845eb51d16
-- Tables                community_salesforce.account, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  p.name AS ProviderName,
  a.hmc_franchise_number_c AS FranchiseNumber,
  a.hmc_alternate_account_phone_1_c AS AlternatePhone1,
  a.hmc_alternate_account_phone_2_c AS AlternatePhone2
FROM main.prod_homecare_actransactional_organization.provider AS p
LEFT JOIN main.community_salesforce.account AS a
  ON a.hmc_cart_provider_id_c = p.providerid
WHERE
  p.providerorganizationid = 117
