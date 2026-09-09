-- Power BI query shape 577 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             68,108
-- Rows returned         65,699
-- Avg duration          866 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.othercharge, prod_homecare_actransactional_billing.otherchargetype, prod_homecare_actransactional_billing.payment
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    p.AccountID,
    p.amount,
    p.createdon,
    DATE_FORMAT(p.createdon, 'yyyyMM') AS PaymentMonthYearId,
    CASE WHEN p.paymentstatustypeid = 1 THEN 'Payment' ELSE NULL END AS Payment
  FROM main.prod_homecare_actransactional_billing.payment AS p
  WHERE
    p.paymentstatustypeid = 1 AND p.createdon >= '2024'
  UNION
  SELECT
    p.AccountID,
    p.amount,
    p.createdon,
    DATE_FORMAT(p.createdon, 'yyyyMM') AS PaymentMonthYearId,
    oct.name AS OtherChargeType
  FROM main.prod_homecare_actransactional_billing.othercharge AS p
  LEFT JOIN main.prod_homecare_actransactional_billing.otherchargetype AS oct
    ON oct.otherchargetypeid = p.otherchargetypeid
  WHERE
    p.otherchargetypeid IN (2, 10)
)
SELECT
  *
FROM CTE
