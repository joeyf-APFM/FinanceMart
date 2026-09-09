-- Power BI query shape 280 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            92
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             210,151,509
-- Rows returned         111,842,268
-- Avg duration          4,475 ms
-- Power BI datasets     392d03ed-c952-4264-963d-fc700b0edcda
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.providerservicecoverage, prod_ygl_apfm.region, prod_ygl_apfm.region_use, prod_ygl_apfm.zip_region, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE1 AS (
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
), CTE AS (
  SELECT DISTINCT
    CASE WHEN zip5 IS NULL THEN 'Other' ELSE 'South Texas' END AS DMA,
    dma.zip
  FROM main.reporting.dim_geography_zip_dma AS dma
  LEFT JOIN CTE1
    ON cte1.zip5 = dma.zip
), CTEA AS (
  SELECT DISTINCT
    cph.date,
    DATE_FORMAT(cph.date, 'yyyyMM') AS monthyearid,
    CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrderID,
    CASE
      WHEN cph.orderstatus = 'Active' AND cph.date = LAST_DAY(cph.date)
      THEN CONCAT(cph.providerid, '-', cph.orderid)
      ELSE NULL
    END AS ActiveEOM,
    psc.postalcode
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  WHERE
    (
      cph.date = LAST_DAY(cph.date) OR cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
    )
    AND cph.date >= '2026'
    AND (
      cph.orderstatusreason = 'Monthly Cap Reached'
      OR cph.orderstatus IN ('Active', 'Paused')
    )
    AND cph.contracttype = 'CPL'
    AND psc.deleted = 0
)
SELECT
  Date,
  DMA,
  monthyearid,
  postalcode,
  ProviderOrderID AS ActivePlus,
  ActiveEOM
FROM CTEA
LEFT JOIN cte
  ON cte.zip = ctea.postalcode
