-- Power BI query shape 489 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             8,378,241
-- Rows returned         11,072
-- Avg duration          4,775 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, reporting.dim_geography_zip_dma
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
    ON IF(
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
    cph.monthlysent,
    dma.DMA
  /*  ,cph.ordername */
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = p.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
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
    AND cph.orderid <> 2774
    AND psc.deleted = 0
    AND DMA <> 'NA'
  ORDER BY
    Date DESC,
    cap DESC
), CTEA AS (
  SELECT DISTINCT
    cph.orderid,
    COUNT(DISTINCT psc.postalcode) AS OrderZips,
    DMA.DMA,
    DMA2.TotalOrderZips,
    cph.date
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = psc.postalcode
  LEFT JOIN (
    SELECT DISTINCT
      cph.orderid,
      cph.date,
      COUNT(psc.postalcode) AS TotalOrderZips
    FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
      ON psc.providerid = cph.providerid
    LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
      ON dma.zip = psc.postalcode
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
      AND dma.dma <> 'NA'
      AND psc.deleted = 0
      AND cph.date >= '2024'
    GROUP BY
      cph.orderid,
      cph.date
  ) AS DMA2
    ON DMA2.orderid = cph.orderid AND dma2.date = cph.date
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
    AND psc.deleted = 0
    AND dma.dma <> 'NA'
    AND cph.orderid <> 2774
    AND cph.date >= '2024'
  GROUP BY
    1,
    3,
    4,
    5
), CTEB AS (
  SELECT
    CTEA.OrderID,
    ROUND(OrderZips / totalorderzips, 2) AS CapPercentage,
    Date,
    DMA
  FROM CTEA
  WHERE
    orderid <> 2774
), CTE3 AS (
  SELECT
    CTE2.Date,
    CTE2.DMA,
    DATE_FORMAT(CTE2.date, 'yyyyMM') AS MonthYear,
    CTE2.Org,
    (
      CTE2.Cap * CTEB.CapPercentage
    ) AS cap,
    CTE2.OrderID
  FROM CTE2
  LEFT JOIN CTEB
    ON CTEB.OrderID = CTE2.OrderID AND CTEB.Date = CTE2.Date AND cteb.dma = cte2.dma
)
SELECT
  Date,
  DMA,
  MonthYear,
  Org,
  ROUND(SUM(cap), 0) AS Adjust_MonthlyCap,
  COUNT(DISTINCT orderid) AS Orders
FROM CTE3
GROUP BY
  1,
  2,
  3,
  4
