-- Power BI query shape 185 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            265
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             222,614,249
-- Rows returned         481,061
-- Avg duration          2,327 ms
-- Power BI datasets     95e62086-9ac7-4ac5-81fb-5c045316c4fc
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.date,
    DATE_FORMAT(cph.date, 'yyyyMM') AS MonthYearID,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    CONCAT(cph.providerid, '-', cph.orderid) AS ProviderOrders,
    COUNT(DISTINCT cph.date) AS Days
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = cph.providerid
  WHERE
    date >= '2024'
    AND cph.contracttype = 'CPL'
    AND cph.orderstatusreason = 'Monthly Cap Reached'
  GROUP BY
    1,
    2,
    3,
    4
), CTE1 AS (
  SELECT DISTINCT
    providerorders,
    SUM(days) OVER (PARTITION BY MonthYearID, providerorders, org ORDER BY date) AS days,
    date,
    monthyearid,
    org
  FROM CTE
  GROUP BY
    date,
    monthyearid,
    days,
    providerorders,
    org
)
SELECT
  Date,
  COUNT(DISTINCT providerorders) AS ProviderOrders,
  SUM(days),
  monthyearid,
  org
FROM CTE1
GROUP BY
  date,
  monthyearid,
  org
