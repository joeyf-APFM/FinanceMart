-- Power BI query shape 161 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            299
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             566,324,277
-- Rows returned         21,875,166
-- Avg duration          2,800 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    YEAR(Date),
    MONTH(Date),
    OrderID,
    cph.ProviderID,
    MAX(Date) AS LastDay,
    MAX(CASE WHEN monthlycap IS NULL THEN 'Yes' ELSE 'No' END) AS UnlimitedCap,
    MAX(
      CASE
        WHEN cph.ProviderName LIKE '%firstlight%'
        THEN 'Maria Pacheco'
        WHEN cph.Date <= '2025-04-28'
        THEN csmfix.CSM
        WHEN cph.csm IS NULL OR (
          cph.csm = 'Account Support Team' AND org.name IS NULL
        )
        THEN 'Independent'
        ELSE cph.CSM
      END
    ) AS CSMF,
    MAX(org.name) AS name,
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
  LEFT JOIN (
    SELECT
      ProviderID,
      CSM
    FROM prod_homecare_acreporting_reporting.cartproviderhistory
    WHERE
      Date = '2025-04-28'
  ) AS csmfix
    ON csmfix.ProviderID = cph.providerid
  WHERE
    Date >= '2025-02-01'
    AND contracttype = 'CPL'
    AND (
      cph.orderstatus IN ('Active', 'Paused')
      OR cph.orderstatusreason = 'Monthly Cap Reached'
    )
  GROUP BY
    YEAR(Date),
    MONTH(Date),
    OrderID,
    cph.ProviderID
)
SELECT
  *,
  CASE
    WHEN CSMF = 'Account Support Team' AND name IS NULL
    THEN 'Independent'
    ELSE csmf
  END AS CSMFixed
FROM CTE
