-- Power BI query shape 466 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             0
-- Rows returned         0
-- Avg duration          235 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  c.hmc_case_subject_c AS CaseSubject,
  c.account_id AS SalesforceAccount,
  a.id AS AccountID,
  a.name AS AccoutName,
  a.hmc_cart_provider_id_c AS ProviderID,
  o.accountid
FROM main.community_salesforce.case AS c
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = c.account_id
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.providerid = a.hmc_cart_provider_id_c
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = op.orderid
WHERE
  c.hmc_case_subject_c LIKE 'AM - Cancellation: Pending%'
  OR c.hmc_case_subject_c = 'AM - Cancellation: Processed'
