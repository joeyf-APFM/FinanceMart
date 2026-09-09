-- Power BI query shape 547 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             62,665
-- Rows returned         61,654
-- Avg duration          910 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.payment
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.AccountID,
  p.amount,
  p.createdon,
  DATE_FORMAT(p.createdon, 'yyyyMM') AS PaymentMonthYearId,
  p.paymentstatustypeid
FROM main.prod_homecare_actransactional_billing.payment AS p
WHERE
  p.paymentstatustypeid = 1 AND p.createdon >= '2024'
