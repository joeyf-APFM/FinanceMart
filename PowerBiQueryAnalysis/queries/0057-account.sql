-- Power BI query shape 57 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,583
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,670,265,650
-- Rows returned         2,091,254
-- Avg duration          2,800 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.case_history, community_salesforce.opportunity, prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    o.owner_id,
    a.hmc_cart_provider_id_c AS ProviderID,
    a.id AS SF_AccountID
  FROM main.community_salesforce.opportunity AS o
  LEFT JOIN main.community_salesforce.account AS a
    ON a.id = o.account_id
  WHERE
    o.is_won = TRUE AND o.close_date >= '2026-01-01'
), CTE1 AS (
  SELECT
    CTE.ProviderID,
    cph.OrderID,
    CTE.SF_AccountID,
    owner_id,
    MIN(cph.date) AS FirstActiveDate
  FROM CTE
  JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = cte.providerid
  WHERE
    cph.contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
  GROUP BY
    1,
    2,
    3,
    4
), CTEA AS (
  SELECT
    c.account_id,
    c.id
  FROM main.community_salesforce.case AS c
  JOIN main.community_salesforce.case_history AS ch
    ON ch.case_id = c.id
  WHERE
    c.type = 'Independent Onboarding' AND ch.new_value = 'Invite sent'
)
SELECT DISTINCT
  CTE1.ProviderID,
  CTE1.OrderID,
  CONCAT(CTE1.ProviderID, '-', CTE1.OrderID) AS ProviderOrder,
  CTE1.SF_AccountID,
  CTE1.Owner_ID,
  CTE1.FirstActiveDate,
  CASE WHEN CTEA.id IS NULL THEN 0 ELSE 1 END AS InviteSent,
  c.type
FROM CTE1
LEFT JOIN CTEA
  ON CTEA.account_id = CTE1.SF_AccountID
LEFT JOIN main.community_salesforce.case AS c
  ON c.account_id = cte1.sf_accountid
WHERE
  CTE1.FirstActiveDate >= '2026-01-01' AND c.type = 'Independent Onboarding'
