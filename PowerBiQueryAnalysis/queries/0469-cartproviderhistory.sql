-- Power BI query shape 469 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,210,602
-- Rows returned         64,565
-- Avg duration          1,427 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
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
    LAST_DAY(cph.date) AS LastDay,
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
    LAST_DAY(cph.date)
)
SELECT
  ProviderID,
  ProviderName,
  CTE.OrderID,
  LastDay,
  FirstActiveDate,
  LastActiveDate,
  CurrentOrderStatus,
  CASE
    WHEN CurrentOrderStatusReasonType = 'InsufficientBalance' AND NOT o.orderid IS NULL
    THEN 'Monthly Cap Reached'
    ELSE CurrentOrderStatusReasonType
  END AS CurrentOrderStatusReasonType,
  HCAM,
  CSM,
  CONCAT(providerid, '-', cte.orderid) AS providerorders,
  DATEDIFF(DAY, firstactivedate, LastActiveDate) AS DaystoCancel,
  CASE
    WHEN CurrentOrderStatusReasonType = 'Monthly Cap Reached'
    THEN 0
    WHEN NOT o.orderid IS NULL AND CurrentOrderStatusReasonType = 'InsufficientBalance'
    THEN 0
    WHEN CurrentOrderStatus IN ('Suspended', 'Cancelled')
    THEN 1
    ELSE 0
  END AS Attrition,
  CASE
    WHEN CurrentOrderStatus IN ('Active', 'Paused')
    OR CurrentOrderStatusReasonType = 'Monthly Cap Reached'
    THEN 1
    WHEN NOT o.orderid IS NULL AND CurrentOrderStatusReasonType = 'InsufficientBalance'
    THEN 1
    ELSE 0
  END AS Retention,
  ROW_NUMBER() OVER (PARTITION BY CONCAT(providerid, '-', cte.orderid) ORDER BY lastactivedate DESC) AS rn,
  CASE WHEN o.orderid IS NULL THEN 0 ELSE 1 END AS prepaid
FROM CTE
LEFT JOIN (
  SELECT
    orderid,
    prepaidtotal
  FROM main.prod_homecare_actransactional_ordermanagement.order
  WHERE
    prepaidtotal >= 580
) AS o
  ON o.orderid = cte.orderid
WHERE
  lastday > '2025-07-01'
