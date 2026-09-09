-- Power BI query shape 222 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             208,363,126
-- Rows returned         189,253,776
-- Avg duration          2,897 ms
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
    AND OrderStatus IN ('Suspended')
    AND OrderStatusReason <> 'Monthly Cap Reached'
    AND (
      CCFail = 0 OR CCFail IS NULL
    )
    AND OrderID <> 12705
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
