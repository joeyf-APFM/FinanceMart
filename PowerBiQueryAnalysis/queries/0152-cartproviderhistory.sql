-- Power BI query shape 152 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            306
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             47,554,604
-- Rows returned         858,974
-- Avg duration          1,965 ms
-- Power BI datasets     c38af845-cf82-47a4-9373-12845eb51d16
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  cph.providerid,
  cph.orderid,
  cph.orderstatus,
  cph.contracttype,
  CASE WHEN cph.monthlycap IS NULL THEN 'Unlimited' ELSE cph.monthlycap END AS MonthlyCap,
  DATE_FORMAT(cph.date, 'yyyyMM') AS Month
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cph.providerid
WHERE
  p.providerorganizationid = 117
  AND (
    cph.date = LAST_DAY(cph.date) OR cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
  )
  AND cph.date >= '2025'
  AND cph.contracttype IN ('CPL', 'CPA')
