-- Power BI query shape 354 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            14
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             91,951,270
-- Rows returned         13,874
-- Avg duration          424 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.pausereferralrequest, prod_homecare_actransactional_organization.provider
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
    p.providerorganizationid = 123
    AND (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
  GROUP BY
    1,
    2
), CTEA AS (
  SELECT
    cte.providerid,
    fromdate,
    resumedate
  FROM CTE
  JOIN main.prod_homecare_actransactional_organization.pausereferralrequest AS p
    ON p.providerid = cte.providerid
  WHERE
    approved = TRUE
    AND CAST(CURRENT_TIMESTAMP() AS DATE) >= fromdate
    AND CAST(CURRENT_TIMESTAMP() AS DATE) <= resumedate
)
SELECT DISTINCT
  CTE.ProviderID,
  CTE.OrderID,
  CTE.FirstActive,
  CTE.LastActive,
  CASE
    WHEN NOT ctea.providerid IS NULL
    AND NOT ost.name IN ('Completed', 'Cancelled', 'Suspended')
    THEN 'Paused'
    ELSE ost.name
  END AS OrderStatus,
  CASE
    WHEN NOT ctea.providerid IS NULL
    AND NOT ost.name IN ('Completed', 'Cancelled', 'Suspended')
    THEN 'Provider Pause'
    ELSE osrt.name
  END AS OrderReason,
  CTEa.resumedate,
  op.monthlycap
FROM CTE
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = cte.orderid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.orderid = cte.orderid AND op.providerid = cte.providerid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN CTEA
  ON CTEA.providerid = cte.providerid
