-- Power BI query shape 394 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             26,642,316
-- Rows returned         10,633
-- Avg duration          4,636 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    a.AccountID,
    a.name AS AccountName,
    ast.name AS AccountStatus,
    a.accountstatusreasonnote,
    o.orderid,
    o.name AS OrderName,
    ost.name AS OrderStatus,
    osrt.name AS OrderStatusReason,
    p.providerid,
    p.name AS ProviderName
  FROM main.prod_homecare_actransactional_billing.account AS a
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
    ON ast.accountstatustypeid = a.accountstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = a.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = op.providerid
  WHERE
    ast.name = 'Closed' AND o.billingtypeid = 3
), CTEA AS (
  SELECT
    CTE.ProviderID,
    COUNT(DISTINCT o.orderid) AS OtherOrders
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  WHERE
    ost.name IN ('Active', 'Paused', 'Suspended') AND o.billingtypeid = 3
  GROUP BY
    1
), CTEB AS (
  SELECT
    CTE.ProviderID,
    COUNT(DISTINCT o.orderid) AS OnboardingOrders
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  WHERE
    ost.name = 'Onboarding' AND o.billingtypeid = 3
  GROUP BY
    1
), CTE1 AS (
  SELECT
    CTE.*,
    CTEA.OtherOrders,
    CTEB.onboardingorders
  FROM CTE
  LEFT JOIN CTEA
    ON CTEA.ProviderID = CTE.ProviderID
  LEFT JOIN CTEB
    ON CTEB.ProviderID = CTE.ProviderID
), CTEC AS (
  SELECT
    cph.ProviderID,
    p.name AS ProviderName,
    cph.OrderID,
    o.createdon AS OrderCreateDate,
    MIN(Date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate,
    ost.name AS CurrentOrderStatus,
    osrt.name AS CurrentOrderStatusReason,
    cph.accountid
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
    cph.accountid
)
SELECT
  CTE1.AccountID,
  CTE1.AccountName,
  CTE1.AccountStatus,
  CTE1.AccountStatusReasonNote,
  CTEC.OrderID,
  CTE1.OrderName,
  CTE1.OrderStatus,
  CTE1.OrderStatusReason,
  CTEC.FirstActiveDate,
  CTEC.LastActiveDate,
  CTEC.ProviderID,
  CTE1.ProviderName,
  CTE1.OtherOrders,
  CTE1.OnboardingOrders,
  CONCAT(CTEc.providerid, '-', ctec.orderid) AS ProviderOrderID,
  dma,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
FROM CTE1
LEFT JOIN CTEC
  ON CTEC.accountid = CTE1.AccountID
  AND ctec.providerid = cte1.providerid
  AND cte1.orderid = ctec.orderid
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ctec.providerid
LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
  ON dma.zip = p.postalcode
WHERE
  dma.dma <> 'NA'
