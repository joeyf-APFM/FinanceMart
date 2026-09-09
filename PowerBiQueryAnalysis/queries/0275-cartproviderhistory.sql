-- Power BI query shape 275 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            102
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             347,459,829
-- Rows returned         8,300
-- Avg duration          19,554 ms
-- Power BI datasets     392d03ed-c952-4264-963d-fc700b0edcda
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, prod_ygl_apfm.region, prod_ygl_apfm.region_use, prod_ygl_apfm.zip_region, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    date,
    DATE_FORMAT(cph.date, 'MMyyyy') AS MonthYear,
    monthlysent,
    monthlycap
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  WHERE
    cph.orderid = 2774
    AND date >= '2025'
    AND (
      date = LAST_DAY(date) OR date = CAST(CURRENT_TIMESTAMP() AS DATE)
    )
), CTE1 AS (
  SELECT DISTINCT
    cph.date,
    DATE_FORMAT(cph.date, 'MMyyyy') AS MonthYear,
    CASE WHEN CTE.date = LAST_DAY(CTE.date) THEN cte.monthlysent ELSE CTE.monthlycap END AS HICap
  FROM cte
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON YEAR(cte.date) = YEAR(cph.date)
    AND IF(
      DAY(cte.date) >= 15,
      (
        DAY(cph.date) = 15 AND MONTH(cph.date) = MONTH(cte.date)
      ),
      CAST(cph.date AS DATE) = cte.date
    )
    AND cph.date >= '2025'
), CTE2 AS (
  SELECT DISTINCT
    cph.date,
    cph.orderid,
    cph.monthlycap,
    CASE
      WHEN cph.orderid = 3265
      THEN 2500
      WHEN cph.orderid = 2774
      THEN CTE1.HICap
      WHEN cph.monthlycap IS NULL AND NOT cph.monthlysent IS NULL
      THEN (
        2 * cph.monthlysent
      )
      WHEN cph.monthlycap IS NULL
      THEN 25
      WHEN cph.monthlycap >= 200 AND cph.monthlysent IS NULL
      THEN 200
      WHEN cph.monthlycap >= 200 AND cph.monthlysent >= 0.5 * cph.monthlycap
      THEN cph.monthlycap
      WHEN cph.monthlycap >= 200 AND cph.monthlysent < 0.5 * cph.monthlycap
      THEN 2 * cph.monthlysent
      WHEN cph.monthlysent IS NULL AND cph.monthlycap IS NULL
      THEN 200
      ELSE cph.monthlycap
    END AS Cap,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    cph.monthlysent
  /*  ,cph.ordername */
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  LEFT JOIN CTE1
    ON cte1.date = cph.date
  WHERE
    (
      DAY(cph.date) = 15
      OR IF(
        DAY(CURRENT_TIMESTAMP()) < 15,
        cph.date = CAST(CURRENT_TIMESTAMP() AS DATE),
        DAY(cph.date) = 15
      )
    )
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND cph.date >= '2024'
    AND contracttype = 'CPL'
  ORDER BY
    Date DESC,
    cap DESC
), CTEA AS (
  SELECT DISTINCT
    CTE2.orderid,
    cph.date,
    COUNT(DISTINCT psc.postalcode) AS PostalCodes
  FROM CTE2
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.orderid = cte2.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  /* LEFT JOIN main.reporting.dim_geography_zip_dmaa dma on dma.zip = psc.postalcode */
  WHERE
    (
      DAY(cph.date) = 15
      OR IF(
        DAY(CURRENT_TIMESTAMP()) < 15,
        cph.date = CAST(CURRENT_TIMESTAMP() AS DATE),
        DAY(cph.date) = 15
      )
    )
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND cph.date >= '2024'
    AND contracttype = 'CPL'
    AND psc.deleted = 0
  /* and dma.dma <> 'NA' */
  GROUP BY
    1,
    2
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
    CTEA.OrderID,
    CASE WHEN cteb1.regionName = 'South Texas' THEN 'South Texas' ELSE 'Other' END AS DMA,
    CTEA.postalcodes,
    ctea.date,
    COUNT(DISTINCT psc.postalcode) AS DMAPostalCodes
  FROM CTEA
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.orderid = ctea.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
  LEFT JOIN CTEB1
    ON cteb1.zip5 = psc.postalcode
  WHERE
    (
      DAY(cph.date) = 15
      OR IF(
        DAY(CURRENT_TIMESTAMP()) < 15,
        cph.date = CAST(CURRENT_TIMESTAMP() AS DATE),
        DAY(cph.date) = 15
      )
    )
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND cph.date >= '2024'
    AND contracttype = 'CPL'
    AND psc.deleted = 0
  /* and dma.dma <> 'NA' */
  GROUP BY
    1,
    2,
    3,
    4
), CTEC AS (
  SELECT
    CTEB.OrderID,
    CTEB.PostalCodes,
    CTEB.DMA,
    DMAPostalCodes,
    date,
    dmapostalcodes / postalcodes AS DMAPercentage
  FROM CTEB
), CTE3 AS (
  SELECT
    cte2.Date,
    DATE_FORMAT(cte2.date, 'yyyyMM') AS MonthYear,
    Org,
    cap * dmapercentage AS cap,
    cte2.orderid,
    dmapostalcodes,
    postalcodes,
    dma,
    dmapercentage
  FROM CTE2
  LEFT JOIN CTEC
    ON CTEC.orderid = cte2.orderid AND ctec.date = cte2.date
  WHERE
    cte2.date >= '2025'
)
SELECT
  Date,
  DATE_FORMAT(date, 'yyyyMM') AS MonthYear,
  Org,
  dma,
  SUM(cap) AS Adjust_MonthlyCap,
  COUNT(DISTINCT orderid) AS Orders
FROM CTE3
WHERE
  NOT dma IS NULL
GROUP BY
  1,
  2,
  3,
  4
