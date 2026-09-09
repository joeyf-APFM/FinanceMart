-- Power BI query shape 62 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,481
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             48,609,667
-- Rows returned         6,950,670
-- Avg duration          1,480 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_ordermanagement.order
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    cph.*,
    o.CreatedOn AS OrderCreateDate,
    CASE WHEN o.CostPerLead = 0.1 THEN 34 ELSE o.CostPerLead END AS CostPerLead,
    ROW_NUMBER() OVER (PARTITION BY ProviderID ORDER BY cph.OrderID) AS rn
  FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
    ON o.OrderID = cph.OrderID
  WHERE
    Date = CAST(CURRENT_TIMESTAMP() AS DATE)
    AND ContractType = 'CPL'
    AND (
      OrderStatus IN ('Active', 'Paused') OR OrderStatusReason = 'Monthly Cap Reached'
    )
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
