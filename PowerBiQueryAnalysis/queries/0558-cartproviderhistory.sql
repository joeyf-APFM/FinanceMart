-- Power BI query shape 558 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             462,964
-- Rows returned         69,701
-- Avg duration          3,062 ms
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
    ON cte.monthyear = DATE_FORMAT(cph.date, 'MMyyyy')
    AND DAY(cph.date) = 15
    AND cph.date >= '2025'
)
SELECT DISTINCT
  cph.date,
  cph.orderid,
  DATE_FORMAT(cph.date, 'yyyyMM') AS Monthyear,
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
    WHEN cph.monthlycap >= 200 AND cph.monthlycap < (
      2 * cph.monthlysent
    )
    THEN 2 * cph.monthlysent
    WHEN cph.monthlycap >= 200
    AND (
      cph.monthlycap >= (
        2 * cph.monthlysent
      ) OR cph.monthlysent IS NULL
    )
    THEN 200
    ELSE cph.monthlycap
  END AS Adjust_MonthlyCap,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
  cph.monthlysent
/*  ,cph.ordername */
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cph.providerid
LEFT JOIN CTE1
  ON cte1.date = cph.date
WHERE
  DAY(cph.date) = 15
  AND (
    cph.orderstatus IN ('Active', 'Paused')
    OR cph.orderstatusreason = 'Monthly Cap Reached'
  )
  AND cph.date >= '2024'
  AND contracttype = 'CPL'
ORDER BY
  Date DESC,
  Adjust_MonthlyCap DESC
