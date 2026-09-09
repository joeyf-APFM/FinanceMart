-- Power BI query shape 31 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,262
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             15,414,845,820
-- Rows returned         50,204,242
-- Avg duration          5,696 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimstateprovince, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.ProviderID,
    cph.ProviderName,
    cph.OrderID,
    o.createdon AS OrderCreateDate,
    MIN(Date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate,
    ost.name AS CurrentOrderStatus,
    osrt.name AS CurrentOrderStatusReasonType,
    u2.FirstName AS HCAM,
    u.FirstName AS CSM,
    p.postalcodeid,
    CASE WHEN dpc.code IS NULL THEN p.postalcode ELSE dpc.code END AS PostalCode
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
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS dpc
    ON dpc.postalcodeid = p.postalcodeid
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
    o.ServiceTypeID = 2
    AND o.BillingTypeID = 3
    AND Date >= '2022-01-01'
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
    PostalCode,
    p.postalcodeid,
    p.providerid,
    code
)
SELECT
  cte.*,
  sp.name
FROM CTE
LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
  ON pc.code = PostalCode
LEFT JOIN prod_homecare_acreporting_reporting.dimstateprovince AS sp
  ON sp.stateprovinceid = pc.stateprovinceid
