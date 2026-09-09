-- Power BI query shape 234 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             858,751,166
-- Rows returned         575,190,679
-- Avg duration          4,929 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    Date,
    OrderID,
    AVG(MonthlyCap) AS OrderMonthlyMax,
    AVG(MonthlySent) AS LeadsSent
  FROM prod_homecare_acreporting_reporting.cartproviderhistory
  WHERE
    ContractType = 'CPL'
    AND (
      NOT OrderStatus IN ('Suspended', 'Paused', 'Onboarding')
      OR OrderStatusReason = 'Monthly Cap Reached'
    )
  GROUP BY
    OrderID,
    Date
  ORDER BY
    Date,
    OrderID
)
SELECT
  Date,
  OrderID,
  CASE
    WHEN OrderID = 3265
    THEN 1842
    WHEN OrderMonthlyMax IS NULL
    THEN 25
    ELSE OrderMonthlyMax
  END AS OrderMonthlyMax,
  LeadsSent
FROM CTE
ORDER BY
  Date,
  OrderID
