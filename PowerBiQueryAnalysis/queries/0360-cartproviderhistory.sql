-- Power BI query shape 360 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            12
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,011,838
-- Rows returned         372
-- Avg duration          472 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
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
    AND cph.orderid = 2774
  ORDER BY
    Date DESC,
    cap DESC
)
SELECT
  Date,
  DATE_FORMAT(date, 'yyyyMM') AS MonthYear,
  Org,
  SUM(cap) AS Adjust_MonthlyCap,
  COUNT(DISTINCT orderid) AS Orders
FROM CTE2
GROUP BY
  1,
  2,
  3
