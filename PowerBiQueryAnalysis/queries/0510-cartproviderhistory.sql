-- Power BI query shape 510 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             417,402
-- Rows returned         66
-- Avg duration          31,027 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    cph.date,
    cph.orderid,
    cph.monthlycap,
    CASE
      WHEN cph.orderid = 3265
      THEN 2500
      WHEN cph.orderid = 2774
      THEN 8000
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
    END AS Cap,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    cph.monthlysent
  /*  ,cph.ordername */
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    DAY(date) = 15
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
    AND date >= '2024'
    AND contracttype = 'CPL'
  ORDER BY
    Date DESC,
    cap DESC
)
SELECT
  Date,
  DATE_FORMAT(date, 'MM-yyyy') AS MonthYear, /*  ,Org */
  SUM(cap) AS Adjust_MonthlyCap,
  COUNT(DISTINCT orderid) AS Orders
FROM CTE
GROUP BY
  1,
  2
