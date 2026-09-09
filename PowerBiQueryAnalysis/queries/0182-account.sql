-- Power BI query shape 182 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            269
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             12,976,717
-- Rows returned         123,655
-- Avg duration          1,502 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                community_salesforce.account, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  p.name AS ProviderName,
  a.hmc_franchise_number_c AS FranchiseNumber,
  a.hmc_alternate_account_phone_1_c AS AlternativePhone1,
  a.hmc_alternate_account_phone_2_c AS AlternativePhone2
FROM main.prod_homecare_actransactional_organization.provider AS p
LEFT JOIN main.community_salesforce.account AS a
  ON a.hmc_cart_provider_id_c = p.providerid
WHERE
  p.providerorganizationid = 123
