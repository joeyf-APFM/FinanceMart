-- Power BI query shape 357 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            13
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             19,717,523
-- Rows returned         18,952
-- Avg duration          263 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.providerid,
    cph.orderid,
    MIN(cph.date) AS FirstActiveDate,
    MAX(cph.date) AS LastActiveDate
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
  GROUP BY
    1,
    2
), CTE1 AS (
  SELECT
    CTE.ProviderID,
    p.name AS ProviderNAme,
    CTE.OrderID,
    CTE.FirstActiveDate,
    CTE.LastActiveDate,
    CAST(o.createdon AS DATE) AS OrderCreateDate,
    CASE WHEN cph.orderstatus IS NULL THEN ost.name ELSE cph.orderstatus END AS CurrentOrderStatus,
    CASE
      WHEN cph.orderstatusreason IS NULL
      THEN osrt.name
      ELSE cph.orderstatusreason
    END AS CurrentOrderStatusReasonType,
    u2.firstname AS HCAM
  FROM CTE
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = cte.providerid AND cph.orderid = cte.orderid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` AS o
    ON o.orderid = cte.OrderID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.ProviderID = cte.ProviderID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u
    ON u.UserID = AccountSpecialistUserID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u2
    ON u2.UserID = HCAMUserID
  WHERE
    cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
    AND o.billingtypeid = 3
    AND cte.lastactivedate >= '2025'
)
SELECT
  *,
  CASE
    WHEN (
      cte1.CurrentOrderStatusReasonType = 'Monthly Cap Reached'
      OR cte1.CurrentOrderStatus IN ('Active', 'Paused')
    )
    THEN 'Active+'
    WHEN cte1.CurrentOrderStatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status
FROM CTE1
