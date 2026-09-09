-- Power BI query shape 388 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             33,060,617
-- Rows returned         58,968
-- Avg duration          2,370 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.accountid,
    cph.ProviderID,
    p.name AS ProviderName,
    cph.OrderID,
    o.createdon AS OrderCreateDate,
    MIN(Date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate,
    ost.name AS CurrentOrderStatus,
    osrt.name AS CurrentOrderStatusReasonType,
    u2.FirstName AS HCAM,
    u.FirstName AS CSM
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
    Date >= '2019-01-01'
    AND (
      cph.orderstatus = 'Active'
      OR cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus = 'Paused'
    )
  GROUP BY
    cph.ProviderID,
    p.name,
    cph.OrderID,
    o.createdon,
    ost.name,
    osrt.name,
    u2.FirstName,
    u.FirstName,
    cph.accountid
)
SELECT
  CTE.*,
  DATE_FORMAT(firstactivedate, 'yyyyMM') AS ActiveMonthYearID,
  DATE_FORMAT(ordercreatedate, 'yyyyMM') AS OrderMonthYearID
FROM CTE
WHERE
  ordercreatedate >= '2024'
