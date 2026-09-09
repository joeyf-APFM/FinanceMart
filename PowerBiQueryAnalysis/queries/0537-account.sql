-- Power BI query shape 537 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             50,927
-- Rows returned         2,227
-- Avg duration          306 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.payment, prod_homecare_actransactional_billing.paymentstatustype, prod_homecare_actransactional_ordermanagement.order
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.accountid, /*  ,o.orderid */
  p.amount,
  p.resultmessage,
  pst.name AS PaymentStatus,
  CAST(p.createdon AS DATE) AS PaymentDate, /* ,o.createdon OrderCreateDate */
  ROW_NUMBER() OVER (
    PARTITION BY p.accountid, YEAR(p.createdon), MONTH(p.createdon)
    ORDER BY p.createdon DESC
  ) AS CardRunInMonth
FROM main.prod_homecare_actransactional_billing.payment AS p
LEFT JOIN main.prod_homecare_actransactional_billing.paymentstatustype AS pst
  ON pst.paymentstatustypeid = p.paymentstatustypeid
RIGHT JOIN (
  SELECT DISTINCT
    a.accountid
  FROM prod_homecare_actransactional_billing.account AS a
  LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` AS o
    ON o.accountid = a.accountid
  WHERE
    o.prepaidtotal <> 0 AND NOT prepaidtotal IS NULL AND o.createdon >= '2025-11-01'
) AS ppa
  ON ppa.accountid = p.accountid
WHERE
  p.createdon >= '2025-11-01' /* and p.createdon < '2025-12-31' */
