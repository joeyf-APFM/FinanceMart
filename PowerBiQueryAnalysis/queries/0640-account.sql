-- Power BI query shape 640 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             8,558
-- Rows returned         514
-- Avg duration          1,600 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  a.accountid,
  a.name AS AccountName,
  ast.name AS AccountStatus,
  o.orderid,
  o.name AS OrderName,
  o.createdon AS OrderCreateDate,
  ost.name AS OrderStatus,
  osrt.name AS OrderStatusReason,
  o.prepaidtotal,
  a.balance
FROM main.prod_homecare_actransactional_billing.account AS a
LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
  ON ast.accountstatustypeid = a.accountstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.accountid = a.accountid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
/* a.accountstatustypeid = 1 */
WHERE
  NOT ost.name IN ('Active', 'Onboarding')
  AND /* and a.createdon >= '2025-11-01' */ a.balance < 0
  AND NOT o.prepaidtotal IS NULL
