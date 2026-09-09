-- Power BI query shape 393 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        6 (same query, different literals or projection)
-- Rows read             67,820,052
-- Rows returned         34,348
-- Avg duration          7,264 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.ProviderID,
    cph.OrderID,
    cph.ProviderName,
    o.createdon AS OrderCreateDate,
    MIN(Date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate,
    ost.name AS CurrentOrderStatus,
    osrt.name AS CurrentOrderStatusReasonType
  FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` AS o
    ON o.orderid = cph.OrderID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.ProviderID = cph.ProviderID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u
    ON u.UserID = AccountSpecialistUserID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u2
    ON u2.UserID = HCAMUserID
  WHERE
    Date >= '2022-01-01'
    AND (
      cph.orderstatus = 'Active'
      OR cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus = 'Paused'
    )
    AND ContractType = 'CPL'
  GROUP BY
    cph.ProviderID,
    cph.ProviderName,
    cph.OrderID,
    o.createdon,
    ost.name,
    osrt.name
)
SELECT
  cte.*,
  CASE
    WHEN LOWER(cph.ProviderName) LIKE '%firstlight%'
    OR LOWER(cph.Providername) LIKE '%firstlight%'
    THEN 'Maria Pacheco'
    WHEN cte.LastActiveDate <= '2025-04-28' AND orgfix.CSM IS NULL
    THEN cph.CSM
    WHEN cte.LastActiveDate <= '2025-04-28' AND NOT orgfix.CSM IS NULL
    THEN orgfix.CSM
    WHEN cph.csm IS NULL
    THEN 'Independent'
    ELSE cph.CSM
  END AS CSMFixed
FROM CTE AS cte
LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  ON cph.ProviderID = cte.ProviderID AND cph.Date = cte.LastActiveDate
LEFT JOIN (
  SELECT
    ProviderID,
    CSM
  FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    Date = '2025-04-28'
) AS orgfix
  ON orgfix.ProviderID = cte.ProviderID
WHERE
  CurrentOrderStatus = 'Cancelled' AND cph.OrderID <> '3192'
