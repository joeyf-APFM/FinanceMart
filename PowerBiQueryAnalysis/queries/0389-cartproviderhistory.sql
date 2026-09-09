-- Power BI query shape 389 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             31,677,221
-- Rows returned         29,509
-- Avg duration          763 ms
-- Power BI datasets     eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.providerid,
    p.name AS ProviderName,
    cph.orderid,
    ost.name AS OrderStatus,
    osrt.name AS OrderStatusReason,
    MIN(cph.date) AS FirstActive,
    MAX(cph.date) AS LastActive
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = cph.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  WHERE
    (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
  GROUP BY
    1,
    2,
    3,
    4,
    5
), CTEA AS (
  SELECT
    cph.providerid,
    cph.orderid,
    cph.orderstatus,
    cph.orderstatusreason
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
), CTE1 AS (
  SELECT DISTINCT
    CTE.ProviderID,
    CTE.ProviderName,
    CTE.OrderID,
    CTE.FirstActive,
    CTE.LastActive,
    CASE WHEN ctea.orderstatus IS NULL THEN cte.orderstatus ELSE ctea.orderstatus END AS OrderStatus,
    CASE
      WHEN ctea.orderstatusreason IS NULL
      THEN cte.orderstatusreason
      ELSE ctea.orderstatusreason
    END AS OrderStatusReason
  FROM CTE
  LEFT JOIN CTEA
    ON CTEA.providerid = cte.providerid AND CTEA.orderid = cte.orderid
  WHERE
    cte.lastactive >= '2026'
)
SELECT
  CTE1.*,
  CONCAT(cte1.providerid, '-', cte1.orderid) AS ProviderOrderID,
  CASE
    WHEN orderstatusreason = 'Monthly Cap Reached' OR orderstatus IN ('Active', 'Paused')
    THEN 'Active+'
    WHEN orderstatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status,
  po.name AS Org,
  DATEDIFF(DAY, cte1.firstactive, cte1.lastactive) AS DaysActive
FROM CTE1
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cte1.providerid
LEFT JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
  ON p.providerorganizationid = po.providerorganizationid
WHERE
  orderid <> 12705
