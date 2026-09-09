-- Power BI query shape 609 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,359,350
-- Rows returned         69
-- Avg duration          5,241 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    cph.ProviderID,
    cph.ProviderName,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS ProviderType,
    cph.OrderID,
    CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrder,
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
    osrt.name,
    u2.FirstName,
    u.FirstName,
    ProviderType,
    CONCAT(cph.providerid, '-', cph.orderid)
), CTE1 AS (
  SELECT
    CTE.*,
    DATEDIFF(DAY, FirstActiveDate, LastActiveDate) AS Days_Active
  FROM CTE
  WHERE
    (
      LOWER(ProviderName) NOT LIKE '%home instead%'
      AND LOWER(ProviderName) NOT LIKE 'senior helpers%'
    )
    AND CurrentOrderStatus = 'Cancelled'
)
SELECT DISTINCT
  CONCAT((
    FLOOR(Days_Active / 30) * 30
  ), '-', (
    FLOOR(Days_Active / 30) * 30
  ) + 30) AS DaysActiveBucket,
  COUNT(DISTINCT ProviderOrder) AS ProviderOrders,
  (
    FLOOR(Days_Active / 30) * 30
  ) AS sort,
  ProviderType
FROM CTE1
GROUP BY
  CONCAT((
    FLOOR(Days_Active / 30) * 30
  ), '-', (
    FLOOR(Days_Active / 30) * 30
  ) + 30),
  (
    FLOOR(Days_Active / 30) * 30
  ),
  ProviderType
