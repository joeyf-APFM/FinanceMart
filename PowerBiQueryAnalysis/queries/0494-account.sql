-- Power BI query shape 494 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             1,386,814
-- Rows returned         2,249
-- Avg duration          1,660 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE /* and hmc_date_resolved_c >= '2025-10-01' */ AS (
  SELECT
    c.case_number AS CaseNumber,
    c.hmc_case_subject_c AS CaseSubject,
    c.created_date AS CreatedDate,
    c.hmc_date_opened_c AS DateOpened,
    c.hmc_date_resolved_c AS DateResolved,
    c.hmc_save_method_used_c AS SaveMethodUsed,
    c.account_id,
    CONCAT(u.first_name, ' ', u.last_name) AS Name,
    u.id AS UserID,
    a.id AS AccountID,
    a.name AS AccoutName,
    a.hmc_cart_provider_id_c AS ProviderID,
    CONCAT('https://placeformom2.lightning.force.com/lightning/r/Account/', a.id, '/view') AS AccountUrl
  FROM main.community_salesforce.case AS c
  LEFT JOIN main.community_salesforce.user AS u
    ON u.id = c.owner_id
  LEFT JOIN main.community_salesforce.account AS a
    ON a.id = c.account_id
  WHERE
    c.owner_id = '005PY000007921mYAA' /* miko */
), CTEA AS (
  SELECT
    CTE.AccountID,
    CAST(MAX(cte.DateResolved) AS DATE) AS LastDateSaved
  FROM CTE
  WHERE
    casesubject = 'AM - Cancellation: Saved'
  GROUP BY
    1
)
SELECT
  CTE.*,
  CTEA.LastDateSaved
FROM CTE
LEFT JOIN CTEA
  ON CTEA.accountid = CTE.account_id
