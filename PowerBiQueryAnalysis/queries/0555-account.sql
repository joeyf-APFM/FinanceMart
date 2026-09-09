-- Power BI query shape 555 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6
-- Rows returned         2
-- Avg duration          1,083 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  c.case_number,
  c.hmc_case_subject_c,
  c.created_date,
  c.hmc_date_opened_c,
  c.hmc_date_resolved_c,
  c.hmc_save_method_used_c,
  c.account_id,
  CONCAT(u.first_name, ' ', u.last_name) AS Name,
  u.id AS UserID,
  a.id AS AccountID,
  a.name AS AccoutName,
  a.hmc_cart_provider_id_c,
  CONCAT('https://placeformom2.lightning.force.com/lightning/r/Account/', a.id, '/view') AS AccountUrl
FROM main.community_salesforce.case AS c
LEFT JOIN main.community_salesforce.user AS u
  ON u.id = c.owner_id
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = c.account_id
WHERE
  c.owner_id = '005PY000007921mYAA' /* miko */
  AND /* and hmc_date_resolved_c >= '2025-10-01' */ c.account_id = '001PY00000bGadQYAS'
