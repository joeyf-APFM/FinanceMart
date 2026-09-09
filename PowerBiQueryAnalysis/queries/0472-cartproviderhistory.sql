-- Power BI query shape 472 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             32,108,382
-- Rows returned         4,252
-- Avg duration          1,108 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_billing.othercharge, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.providerid,
    cph.orderid,
    MIN(cph.date) AS FirstActive,
    MAX(cph.date) AS LastActive
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
    AND cph.contracttype = 'CPL'
    AND p.providerorganizationid IS NULL
  GROUP BY
    1,
    2
), CTE1 AS (
  SELECT
    CTE.ProviderID,
    CTE.OrderID,
    CTE.FirstActive,
    CTE.LastActive,
    DATEDIFF(DAY, cte.firstactive, cte.lastactive) AS DaysActive,
    ost.name AS OrderStatus,
    CASE
      WHEN o.prepaidtotal >= 290 AND osrt.name = 'InsufficientBalance'
      THEN 'Monthly Cap Reached'
      ELSE osrt.Name
    END AS OrderReason,
    CASE WHEN o.prepaidtotal >= 290 THEN 'Prepaid' ELSE 'PAYG' END AS OrderType
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = cte.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  WHERE
    FirstActive >= '2026'
), CTEA AS (
  SELECT
    CTE1.ProviderID,
    CTE1.OrderID,
    FirstActive,
    COUNT(DISTINCT ref.referralid) AS Referrals90
  FROM CTE1
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.providerid = cte1.providerid AND ref.orderid = cte1.orderid
  WHERE
    NOT ref.hmcleadid IS NULL
    AND ref.billingtypeid = 3
    AND DATEDIFF(DAY, firstactive, CAST(ref.referredon AS DATE)) <= 90
    AND DATEDIFF(DAY, firstactive, CAST(ref.referredon AS DATE)) >= 0
  GROUP BY
    1,
    2,
    3
), CTEB AS (
  SELECT
    CTE1.ProviderID,
    CTE1.OrderID,
    FirstActive,
    COUNT(DISTINCT ref.referralid) AS LifetimeReferrals,
    MIN(CAST(ref.activatedon AS DATE)) AS FirstActivation
  FROM CTE1
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.providerid = cte1.providerid AND ref.orderid = cte1.orderid
  WHERE
    NOT ref.hmcleadid IS NULL AND ref.billingtypeid = 3
  GROUP BY
    1,
    2,
    3
), CTEC AS (
  SELECT
    op.providerid,
    op.orderid,
    MAX(CAST(oc.createdon AS DATE)) AS LastFreeLead,
    SUM(amount) AS FreeLeads
  FROM cte1
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = cte1.orderid AND op.providerid = cte1.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_billing.othercharge AS oc
    ON oc.accountid = o.accountid
  WHERE
    otherchargetypeid = 1 AND LOWER(note) LIKE '%free lead%'
  GROUP BY
    1,
    2
)
SELECT
  CTE1.*,
  ctea.Referrals90,
  cteb.LifetimeReferrals,
  ctec.FreeLeads,
  lastfreelead,
  FirstActivation,
  CASE WHEN NOT FirstActivation IS NULL THEN 'Activation' ELSE 'No Activation' END AS HasActivation,
  DATEDIFF(DAY, cte1.firstactive, lastfreelead),
  DATEDIFF(DAY, cte1.firstactive, CURRENT_TIMESTAMP()) AS ProvOrderAge,
  CASE
    WHEN cte1.orderstatus IN ('Active', 'Paused')
    OR cte1.orderreason = 'Monthly Cap Reached'
    THEN 'Active'
    ELSE 'Inactive'
  END AS Status
FROM CTE1
LEFT JOIN CTEA
  ON CTEA.providerid = cte1.providerid AND ctea.orderid = cte1.orderid
LEFT JOIN CTEb
  ON CTEb.providerid = cte1.providerid AND cteb.orderid = cte1.orderid
LEFT JOIN CTEc
  ON CTEc.providerid = cte1.providerid AND ctec.orderid = cte1.orderid
