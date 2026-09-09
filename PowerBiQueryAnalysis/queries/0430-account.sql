-- Power BI query shape 430 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             456,531
-- Rows returned         42,477
-- Avg duration          2,619 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatusreasontype, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_billing.othercharge, prod_homecare_actransactional_billing.otherchargetype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatustype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    a.accountid,
    a.name,
    a.balance,
    ast.name AS AccountStatus,
    asrt.name AS AccountStatusReason,
    a.AccountStatusReasonNote
  FROM main.prod_homecare_actransactional_billing.account AS a
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
    ON ast.accountstatustypeid = a.accountstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatusreasontype AS asrt
    ON asrt.accountstatusreasontypeid = a.accountstatusreasontypeid
  WHERE
    ast.name = 'Closed'
), CTEA AS (
  SELECT
    oc.AccountID,
    oc.amount,
    oc.createdon,
    oct.name AS ChargeType
  FROM main.prod_homecare_actransactional_billing.othercharge AS oc
  LEFT JOIN main.prod_homecare_actransactional_billing.otherchargetype AS oct
    ON oct.otherchargetypeid = oc.otherchargetypeid
  WHERE
    oc.otherchargetypeid IN (2, 10)
), CTEB AS (
  SELECT
    a.accountid, /* ,ost.name */
    COUNT(DISTINCT o.orderid) AS Orders,
    COUNT(DISTINCT ost.name) AS OrderStatus
  FROM main.prod_homecare_actransactional_billing.account AS a
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
    ON ast.accountstatustypeid = a.accountstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = a.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  /*  where a.accountid = 10363 */
  GROUP BY
    1
)
SELECT
  CTE.*,
  CTEA.Amount,
  CTEA.ChargeType,
  o.OrderID,
  ost.name AS OrderStatus
FROM CTE
LEFT JOIN CTEA
  ON CTEA.accountid = cte.accountid
LEFT JOIN CTEB
  ON CTEB.accountid = CTE.accountid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.accountid = CTE.accountid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
WHERE
  cteb.orderstatus = 1
