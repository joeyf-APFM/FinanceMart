-- Power BI query shape 496 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             64,122,831
-- Rows returned         559,938
-- Avg duration          14,059 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    o.AccountID,
    a.name AS AccountName,
    o.OrderID,
    o.name AS OrderName,
    ot.NAme AS OrderStatus,
    ost.Name AS OrderStatusReason,
    o.createdon AS OrderCreateDate,
    u.firstname AS HCAM,
    o.prepaidautorenew,
    o.prepaidtotal
  FROM prod_homecare_actransactional_ordermanagement.order AS o
  LEFT JOIN prod_homecare_actransactional_billing.account AS a
    ON a.AccountID = o.AccountID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS ost
    ON ost.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ot
    ON ot.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = op.providerid
  LEFT JOIN prod_homecare_actransactional_auth.users AS u
    ON u.UserID = p.HCAMUserID
  WHERE
    o.createdon >= '2024' AND ot.name <> 'Onboarding' AND o.billingtypeid = 3
), CTE1 AS (
  SELECT DISTINCT
    CTE.AccountID,
    CTE.AccountName,
    CTE.OrderID,
    CTE.OrderName,
    CTE.OrderStatus AS CurrentOrderStatus,
    CTE.OrderStatusReason AS CurrentOrderStatusReason,
    CTE.OrderCreateDate,
    CTE.HCAM,
    hcc.HomecareChargeID,
    hcc.amount,
    hcc.createdon AS ChargeCreateDate,
    cph.orderstatus AS CPHOrderStatus,
    cph.orderstatusreason AS CPHOrderStatusReason,
    CTE.prepaidautorenew,
    cte.prepaidtotal,
    ROW_NUMBER() OVER (PARTITION BY hcc.homecarechargeid ORDER BY cph.cartproviderhistoryid DESC) AS RN,
    LagDate,
    his.orderstatus AS LastOrderStatus,
    his.orderstatusreason AS LastOrderStatusReason,
    DateSuspended
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.OrderID = CTE.OrderID
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.referralid = ref.referralid
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
    SELECT DISTINCT
      cph.*,
      ROW_NUMBER() OVER (PARTITION BY cph.orderid ORDER BY cph.Date DESC) AS rn,
      LAG(cph.`date`, 1) OVER (PARTITION BY cph.orderid ORDER BY cph.date) AS LagDate
    FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
      ON o.orderid = cph.orderid
    WHERE
      cph.orderstatusreason = 'InsufficientBalance'
      AND (
        o.prepaidtotal < 580 OR o.prepaidtotal IS NULL
      )
  ) AS temp
    ON temp.accountid = cte.accountid AND temp.orderid = cte.orderid AND temp.rn = 1
  LEFT JOIN (
    SELECT
      cph.*,
      date AS DateSuspended,
      ROW_NUMBER() OVER (PARTITION BY cph.orderid ORDER BY cph.Date ASC) AS rn
    FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
      ON o.orderid = cph.orderid
    WHERE
      cph.orderstatusreason = 'InsufficientBalance'
      AND (
        o.prepaidtotal < 580 OR o.prepaidtotal IS NULL
      )
  ) AS temp2
    ON temp2.accountid = cte.accountid AND temp2.orderid = cte.orderid AND temp2.rn = 1
  WHERE
    NOT ref.hmcleadid IS NULL
    AND ref.billingtypeid = 3
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
)
SELECT
  *,
  chargecreatedate AS CreateDate,
  CASE
    WHEN DATEDIFF(DAY, CAST(ADD_MONTHS(ChargeCreateDate, 1) AS DATE), LagDate) > 1
    THEN 1
    ELSE 0
  END AS 1DayLag
FROM CTE1
WHERE
  RN = 1
