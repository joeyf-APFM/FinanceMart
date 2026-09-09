-- Power BI query shape 225 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             9,472,780
-- Rows returned         833,391
-- Avg duration          2,094 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  o.AccountID,
  a.Name AS AccountName
FROM prod_homecare_actransactional_ordermanagement.order AS o
LEFT JOIN prod_homecare_actransactional_billing.account AS a
  ON a.AccountID = o.AccountID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.OrderStatusTypeID = o.OrderStatusTypeID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.OrderStatusReasonTypeID = o.OrderStatusReasonTypeID
WHERE
  (
    NOT osrt.Name IN ('Manual Suspend', 'Account Suspended', 'No Provider Assigned')
    OR osrt.Name IS NULL
  )
  AND ServiceTypeID = 2
  AND BillingTypeID = 3
  AND NOT ost.Name IN ('Completed', 'Cancelled', 'Onboarding')
