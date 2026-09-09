-- Power BI query shape 538 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             918,944
-- Rows returned         2,412
-- Avg duration          312 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.statement, prod_homecare_actransactional_ordermanagement.order
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    a.accountid,
    cph.`date`,
    s.balance,
    o.prepaidtotal,
    LAG(date) OVER (PARTITION BY a.accountid ORDER BY date) AS PriorMonthNotCancelled
  FROM prod_homecare_actransactional_billing.account AS a
  LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` AS o
    ON o.accountid = a.accountid
  LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.accountid = a.accountid
  LEFT JOIN prod_homecare_actransactional_billing.statement AS s
    ON s.accountid = a.accountid AND MONTH(s.createdon) = MONTH(cph.date)
  WHERE
    o.prepaidtotal <> 0
    AND NOT prepaidtotal IS NULL
    AND o.createdon >= '2025-11-01'
    AND NOT o.orderstatustypeid IN (0, 2, 3)
    AND (
      date = LAST_DAY(date) OR DAYOFMONTH(date) = 1
    )
    AND cph.orderstatus <> 'Onboarding'
  ORDER BY
    accountid,
    date
)
SELECT
  *
FROM CTE
WHERE
  DAYOFMONTH(date) = 1 AND DATEDIFF(DAY, PriorMonthNotCancelled, date) = 1
