-- Power BI query shape 417 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             36,485,492
-- Rows returned         5,283
-- Avg duration          4,862 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.opportunity, community_salesforce.user, prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE /* and a.hmc_cart_provider_id_c = 20561 */ AS (
  SELECT
    o.id AS OpportunityID,
    o.close_date,
    a.hmc_cart_provider_id_c AS ProviderID
  FROM main.community_salesforce.opportunity AS o
  JOIN main.community_salesforce.account AS a
    ON a.id = o.account_id
  /* o.is_won = true */
  WHERE
    o.close_date >= '2025-10-01'
), CTEC AS (
  SELECT
    CTE.ProviderID,
    p.name AS ProviderName,
    cph.OrderID,
    CTE.close_date,
    MIN(date) AS FirstActiveDate,
    MAX(date) AS LastActiveDate
  FROM CTE
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
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
    AND /* and p.providerorganizationid is null */ cph.date >= '2025-10-01'
  GROUP BY
    1,
    2,
    3,
    4
), CTE1 AS (
  SELECT DISTINCT
    CTE.ProviderID,
    CASE WHEN CTEC.OrderID IS NULL THEN op.orderid ELSE CTEC.OrderID END AS OrderID,
    CASE WHEN CTEC.ProviderName IS NULL THEN p.name ELSE CTEC.ProviderName END AS ProviderName,
    CASE WHEN CTEC.Close_Date IS NULL THEN CTE.Close_Date ELSE CTEC.Close_Date END AS close_date,
    CTEC.firstactivedate,
    CTEC.lastactivedate
  FROM CTE
  LEFT JOIN CTEC
    ON CTEC.ProviderID = CTE.ProviderID
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = cte.providerid
), CTEB AS (
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
    cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
), CTE2 AS (
  SELECT
    CTE1.ProviderID,
    CTE1.ProviderName,
    CTE1.OrderID,
    CONCAT(CTE1.ProviderID, '-', CTE1.OrderID) AS ProviderOrderID,
    CASE WHEN cteb.orderstatus IS NULL THEN ost.name ELSE 'Cancelled' END AS OrderStatus,
    CASE WHEN cteb.orderstatus IS NULL THEN orst.name ELSE cph.orderstatusreason END AS OrderStatusReason,
    CTE1.Close_Date,
    CTE1.FirstActiveDate,
    CTE1.LastActiveDate,
    DATEDIFF(DAY, CTE1.firstactivedate, CTE1.lastactivedate) AS DaysActive
  /*  ,CASE WHEN ost.name in ('Active', 'Paused') or orst.name in ('Monthly Cap Reached') then 'Active+' else 'Inactive' end Status */
  FROM CTE1
  LEFT JOIN CTEB
    ON CTEB.providerid = cte1.providerid AND cteb.orderid = cte1.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = cte1.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS orst
    ON orst.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = cte1.providerid AND cph.orderid = cte1.orderid
  WHERE
    cph.date = IF(cte1.LastActiveDate IS NULL, CAST(CURRENT_TIMESTAMP() AS DATE), cte1.LastActiveDate)
), CTEA AS (
  SELECT
    ref.providerid,
    ref.orderid,
    MIN(activatedon) AS FirstActivation
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  WHERE
    NOT ref.hmcleadid IS NULL
  GROUP BY
    1,
    2
), CTE3 AS (
  SELECT DISTINCT
    cte2.*,
    CASE
      WHEN orderstatus IN ('Active', 'Paused')
      OR OrderStatusReason IN ('Monthly Cap Reached')
      THEN 'Active+'
      ELSE 'Inactive'
    END AS Status,
    CAST(ctea.FirstActivation AS DATE) AS FirstActivation,
    CASE WHEN CAST(ctea.FirstActivation AS DATE) IS NULL THEN 'No' ELSE 'Yes' END AS HasActivation
  FROM CTE2
  LEFT JOIN CTEA
    ON CTEA.providerid = cte2.providerid AND ctea.orderid = cte2.orderid
  WHERE
    (
      firstactivedate >= '2025-10-01' OR firstactivedate IS NULL
    )
    AND (
      lastactivedate > '2026-01-01' OR lastactivedate IS NULL
    )
), CTED AS (
  SELECT
    CTE3.ProviderID,
    MIN(c.created_date) AS FirstCaseCreateDate
  FROM CTE3
  JOIN main.community_salesforce.account AS a
    ON a.hmc_cart_provider_id_c = CTE3.ProviderID
  JOIN main.community_salesforce.case AS c
    ON c.account_id = a.id
  LEFT JOIN main.community_salesforce.user AS u
    ON u.id = c.owner_id
  WHERE
    c.type = 'Independent Onboarding'
    AND u.name IN ('Cindy Spainhower', 'Jessica Perdue', 'Hannah Guilford')
  GROUP BY
    1
)
SELECT
  CTE3.*,
  CAST(CTED.firstcasecreatedate AS DATE) AS FirstCaseDate
FROM CTE3
LEFT JOIN CTED
  ON CTED.ProviderID = CTE3.ProviderID
WHERE
  lastactivedate >= CAST(CTED.firstcasecreatedate AS DATE)
