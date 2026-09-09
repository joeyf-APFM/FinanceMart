-- Power BI query shape 600 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             5,450,800
-- Rows returned         5,962
-- Avg duration          6,001 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    COUNT(DISTINCT cph.providerid) AS Providers,
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    (
      cph.date = LAST_DAY(cph.date) OR cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
    )
    AND cph.contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND psc.deleted = 0
    AND dma <> 'NA'
    AND cph.date >= '2025-01-01'
  GROUP BY
    3,
    4,
    2
), CTEA AS (
  SELECT DISTINCT
    COUNT(DISTINCT cph.providerid) AS Last3Providers,
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    cph.date >= DATE_ADD(DAY, -2, LAST_DAY(cph.date))
    AND cph.date <= LAST_DAY(cph.date)
    AND cph.contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND psc.deleted = 0
    AND dma <> 'NA'
    AND cph.date >= '2025'
  GROUP BY
    2,
    3,
    4
), CTEB AS (
  SELECT DISTINCT
    COUNT(DISTINCT cph.providerid) AS First3Providers,
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    cph.date <= DATE_ADD(DAY, 2, DATE_TRUNC('MONTH', cph.date))
    AND cph.date >= DATE_TRUNC('MONTH', cph.date)
    AND cph.contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND psc.deleted = 0
    AND dma <> 'NA'
    AND date >= '2025'
  GROUP BY
    2,
    3,
    4
)
SELECT
  CTE.MonthyearID,
  CTE.DMA,
  CTE.Org,
  CTE.Providers,
  CTEA.Last3Providers,
  CTEB.First3Providers
FROM CTE
LEFT JOIN CTEA
  ON CTEA.monthyearid = cte.monthyearid AND ctea.dma = cte.dma AND ctea.org = cte.org
LEFT JOIN CTEB
  ON CTEB.monthyearid = cte.monthyearid AND CTEB.dma = cte.dma AND CTEB.org = cte.org
