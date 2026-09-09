-- Power BI query shape 411 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             36,453,319
-- Rows returned         29,497
-- Avg duration          1,823 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, prod_ygl_apfm.region, prod_ygl_apfm.region_use, prod_ygl_apfm.zip_region
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.providerid,
    cph.orderid,
    MAX(cph.date) AS LastActive,
    MIN(cph.date) AS FirstActive
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
    AND cph.contracttype = 'CPL'
  GROUP BY
    1,
    2
), CTEA AS (
  SELECT DISTINCT
    cph.providerid,
    cph.orderid,
    cph.orderstatus,
    cph.orderstatusreason
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    date = CAST(CURRENT_TIMESTAMP() AS DATE)
), CTEB1 AS (
  SELECT
    r.region_id AS regionId,
    r.region_name AS regionName,
    zr.zip5
  FROM main.prod_ygl_apfm.zip_region AS zr
  JOIN main.prod_ygl_apfm.region AS r
    ON r.region_id = zr.region_id
  JOIN main.prod_ygl_apfm.region_use AS ru
    ON ru.region_id = zr.region_id AND ru.region_type_code = zr.region_type_code
  WHERE
    ru.region_type_code = 'ADVISOR'
    AND r.region_name = 'South Texas'
    AND r.active = 1
    AND zr.`_fivetran_deleted` = FALSE
    AND r.`_fivetran_deleted` = FALSE
    AND ru.`_fivetran_deleted` = FALSE
  ORDER BY
    r.region_id,
    zr.zip5
), CTEB AS (
  SELECT
    psc.providerid,
    COUNT(DISTINCT psc.postalcode) AS ProviderPostalCode,
    COUNT(DISTINCT cteb1.zip5) AS Zip5Cov,
    Zip5Cov / providerpostalcode AS ProviderCoverage
  FROM main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
  LEFT JOIN CTEB1
    ON psc.postalcode = cteb1.zip5
  WHERE
    psc.deleted = 0
  GROUP BY
    1
)
SELECT
  CTE.ProviderID,
  CTE.OrderID,
  CONCAT(CTE.ProviderID, '-', CTE.OrderID) AS ProviderOrders,
  CTE.FirstActive,
  CTE.LastActive,
  p.name AS ProviderName,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
  CASE WHEN CTEA.orderstatus IS NULL THEN ost.name ELSE ctea.orderstatus END AS OrderStatus,
  CASE
    WHEN ctea.orderstatusreason IS NULL
    THEN osrt.name
    ELSE ctea.orderstatusreason
  END AS OrderStatusReason,
  ProviderCoverage,
  CASE
    WHEN (
      ctea.orderstatusreason = 'Monthly Cap Reached'
      OR ctea.orderstatus IN ('Active', 'Paused')
    )
    THEN 'Active+'
    WHEN ctea.orderstatus = 'Onboarding'
    THEN 'Onboarding'
    ELSE 'Inactive'
  END AS Status
FROM CTE
LEFT JOIN CTEA
  ON CTEA.providerid = cte.providerid AND ctea.orderid = cte.orderid
JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON CTE.providerid = p.providerid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = cte.orderid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN CTEB
  ON CTEB.providerid = CTE.providerid
