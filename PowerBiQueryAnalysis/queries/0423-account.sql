-- Power BI query shape 423 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             15,584,669
-- Rows returned         2,320
-- Avg duration          932 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.opportunity, prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    o.id AS OpportunityID,
    o.close_date,
    a.hmc_cart_provider_id_c AS ProviderID
  FROM main.community_salesforce.opportunity AS o
  JOIN main.community_salesforce.account AS a
    ON a.id = o.account_id
  WHERE
    o.is_won = TRUE AND o.close_date >= '2026-01-01'
), CTE1 AS (
  SELECT
    CTE.ProviderID,
    p.name AS ProviderName,
    cph.OrderID,
    CTE.close_date,
    MIN(date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate
  FROM CTE
  JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cte.providerid
  WHERE
    date >= '2022'
    AND cph.contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND p.providerorganizationid IS NULL
  GROUP BY
    1,
    2,
    3,
    4
), CTE2 AS (
  SELECT
    CTE1.ProviderID,
    CTE1.ProviderName,
    CTE1.OrderID,
    CONCAT(CTE1.ProviderID, '-', CTE1.OrderID) AS ProviderOrderID,
    CASE WHEN cph.orderstatus IS NULL THEN ost.name ELSE cph.orderstatus END AS OrderStatus,
    CASE WHEN cph.orderstatus IS NULL THEN orst.name ELSE cph.orderstatusreason END AS OrderStatusReason,
    Close_Date,
    FirstActiveDate,
    LastActiveDate,
    DATEDIFF(DAY, firstactivedate, lastactivedate) AS DaysActive
  /*  ,CASE WHEN ost.name in ('Active', 'Paused') or orst.name in ('Monthly Cap Reached') then 'Active+' else 'Inactive' end Status */
  FROM CTE1
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = cte1.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS orst
    ON orst.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = cte1.providerid AND cph.orderid = cte1.orderid
  WHERE
    firstactivedate >= close_date AND cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
)
SELECT
  *,
  CASE
    WHEN orderstatus IN ('Active', 'Paused')
    OR OrderStatusReason IN ('Monthly Cap Reached')
    THEN 'Active+'
    ELSE 'Inactive'
  END AS Status
FROM CTE2
