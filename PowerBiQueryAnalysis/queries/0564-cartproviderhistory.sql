-- Power BI query shape 564 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             40,102,986
-- Rows returned         228,951
-- Avg duration          14,007 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    o.AccountID,
    a.Name AS AccountName,
    hcamacc.HCAM AS HCAMs,
    o.orderid,
    o.orderstatusreasontypeid,
    o.orderstatustypeid,
    ot.NAme AS OOrderStatus,
    ost.Name AS OrderStatusReason,
    o.createdon AS OrderCreateDate,
    prepaidautorenew
  FROM prod_homecare_actransactional_ordermanagement.order AS o
  LEFT JOIN prod_homecare_actransactional_billing.account AS a
    ON a.AccountID = o.AccountID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS ost
    ON ost.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ot
    ON ot.orderstatustypeid = o.orderstatustypeid
  RIGHT JOIN (
    SELECT DISTINCT
      a.AccountID,
      u2.FirstName AS HCAM
    FROM prod_homecare_actransactional_organization.provider AS p
    LEFT JOIN prod_homecare_actransactional_ordermanagement.orderprovider AS op
      ON op.ProviderID = p.ProviderID
    LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
      ON o.OrderID = op.OrderID
    LEFT JOIN prod_homecare_actransactional_billing.account AS a
      ON a.AccountID = o.AccountID
    LEFT JOIN prod_homecare_actransactional_auth.users AS u
      ON u.UserID = AccountSpecialistUserID
    LEFT JOIN prod_homecare_actransactional_auth.users AS u2
      ON u2.UserID = HCAMUserID
    WHERE
      NOT a.AccountID IS NULL AND NOT u2.FirstName IS NULL
  ) AS hcamacc
    ON hcamacc.AccountID = o.AccountID
  WHERE
    ServiceTypeID = 2 AND BillingTypeID = 3
), CTE1 AS (
  SELECT DISTINCT
    HCAMs AS HCAM,
    (
      amount
    ),
    HomeCareChargeID,
    CTE.accountid,
    CTE.AccountName,
    hcc.createdon AS ChargeCreateDate,
    OrderCreateDate, /* ,add_months(trunc(hcc.createdon,'MM'), 1) ChargeNextMonth */
    CTE.Orderid,
    cph.orderstatus AS CPHOrderStatus,
    cph.orderstatusreason AS CPHOrderStatusReason,
    OOrderStatus AS CurrentOrderStatus,
    orderstatustypeid,
    orderstatusreasontypeid,
    CTE.OrderStatusReason AS CurrentOrderstatusReason,
    prepaidautorenew,
    ROW_NUMBER() OVER (PARTITION BY hcc.homecarechargeid ORDER BY cph.cartproviderhistoryid DESC) AS RN,
    LagDate,
    his.orderstatus AS LastOrderStatus,
    his.orderstatusreason AS LastOrderStatusReason,
    DateSuspended
  FROM prod_homecare_actransactional_billing.homecarecharge AS hcc
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.referralid = hcc.referralid
  JOIN CTE
    ON CTE.accountid = hcc.accountid AND cte.orderid = ref.orderid
  LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON CAST(cph.date AS DATE) = CAST(ADD_MONTHS(hcc.createdon, 1) AS DATE)
    AND cph.accountid = hcc.accountid
    AND CTE.orderid = cph.orderid
  LEFT JOIN (
    SELECT DISTINCT
      orderid,
      accountid,
      orderstatus,
      orderstatusreason,
      ROW_NUMBER() OVER (PARTITION BY orderid ORDER BY Date DESC) AS rn
    FROM prod_homecare_acreporting_reporting.cartproviderhistory
  ) AS his
    ON his.accountid = cte.accountid AND his.orderid = cte.orderid AND his.rn = 1
  LEFT JOIN (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY cph.orderid ORDER BY cph.Date DESC) AS rn,
      LAG(cph.`date`, 1) OVER (PARTITION BY cph.orderid ORDER BY cph.date) AS LagDate
    FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    WHERE
      cph.orderstatusreason = 'InsufficientBalance'
  ) AS temp
    ON temp.accountid = cte.accountid AND temp.orderid = cte.orderid AND temp.rn = 1
  LEFT JOIN (
    SELECT
      *,
      date AS DateSuspended,
      ROW_NUMBER() OVER (PARTITION BY cph.orderid ORDER BY cph.Date ASC) AS rn
    FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    WHERE
      cph.orderstatusreason = 'InsufficientBalance'
  ) AS temp2
    ON temp2.accountid = cte.accountid AND temp2.orderid = cte.orderid AND temp2.rn = 1
  WHERE
    hcc.createdon >= '2025' AND OrderCreateDate >= '2025'
)
SELECT
  *,
  CASE
    WHEN DATEDIFF(DAY, CAST(ADD_MONTHS(ChargeCreateDate, 1) AS DATE), LagDate) > 1
    THEN 1
    ELSE 0
  END AS 1DayLag
FROM CTE1
WHERE
  RN = 1
