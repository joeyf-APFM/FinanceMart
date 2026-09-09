-- Power BI query shape 543 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             5,440
-- Rows returned         5,045
-- Avg duration          753 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.othercharge, prod_homecare_actransactional_billing.otherchargetype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

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
