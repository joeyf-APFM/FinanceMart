-- Power BI query shape 284 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            81
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             85,386,114
-- Rows returned         3,539,003
-- Avg duration          1,460 ms
-- Power BI datasets     eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    DATE_FORMAT(date, 'yyyyMM') AS MonthYearID,
    OrderID,
    cph.ProviderID,
    MAX(Date) AS LastDay,
    MAX(CASE WHEN monthlycap IS NULL THEN 'Yes' ELSE 'No' END) AS UnlimitedCap,
    MAX(
      CASE
        WHEN monthlycap IS NULL AND NOT MonthlySent IS NULL
        THEN MonthlySent
        WHEN monthlycap IS NULL AND Monthlysent IS NULL
        THEN 0
        ELSE Monthlycap
      END
    ) AS MonthlyCap
  FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.ProviderID = cph.ProviderID
  LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS org
    ON org.ProviderOrganizationID = p.ProviderOrganizationID
  WHERE
    Date >= '2026'
    AND contracttype = 'CPL'
    AND (
      (
        cph.orderstatus IN ('Active', 'Paused')
        OR cph.orderstatusreason = 'Monthly Cap Reached'
      )
    )
  GROUP BY
    MonthyearID,
    OrderID,
    cph.ProviderID
)
SELECT
  *
FROM CTE
