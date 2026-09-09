-- Power BI query shape 552 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             546,323
-- Rows returned         6,087
-- Avg duration          1,034 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  c.case_number AS CaseNumber,
  c.hmc_case_subject_c AS CaseSubject,
  c.account_id,
  a.id AS AccountID,
  a.name AS AccoutName,
  a.hmc_cart_provider_id_c AS ProviderID
FROM main.community_salesforce.case AS c
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = c.account_id
WHERE
  c.hmc_case_subject_c LIKE 'AM - Cancellation: Pending%'
  OR c.hmc_case_subject_c = 'AM - Cancellation: Processed'
