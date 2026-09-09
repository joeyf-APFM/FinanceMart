-- Power BI query shape 578 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             25,520,285
-- Rows returned         16,342
-- Avg duration          1,654 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
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
), CTE1 AS (
  SELECT
    CTE.AccountID,
    CTE.ProviderID,
    CTE.ProviderName,
    CTE.OrderID,
    OrderCreateDate,
    FirstActiveDate,
    LastActiveDate,
    CurrentOrderStatus,
    CTE.CurrentOrderStatusReason,
    DATEDIFF(DAY, firstactivedate, LastActiveDate) AS DaystoCancel
  FROM CTE
  WHERE
    CurrentOrderStatus = 'Cancelled'
), CTEA AS (
  SELECT
    ref.orderid,
    ref.providerid,
    COUNT(DISTINCT CASE WHEN ref.returnapproved = TRUE THEN ref.referralid ELSE NULL END) AS ReturnedReferrals,
    COUNT(
      DISTINCT CASE
        WHEN ref.returnapproved = FALSE OR ref.returnapproved IS NULL
        THEN ref.referralid
        ELSE NULL
      END
    ) AS Referrals,
    COUNT(DISTINCT CASE WHEN NOT ref.activatedon IS NULL THEN ref.referralid ELSE NULL END) AS Activations
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  WHERE
    NOT ref.hmcleadid IS NULL
  GROUP BY
    1,
    2
)
SELECT
  CTE1.*,
  CTEA.ReturnedReferrals,
  CTEA.Referrals,
  CTEA.Activations
FROM CTE1
LEFT JOIN CTEA
  ON CTEA.orderid = CTE1.OrderID AND CTEA.providerid = CTE1.ProviderID
