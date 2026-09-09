-- Power BI query shape 329 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             85,558
-- Rows returned         93,679
-- Avg duration          1,353 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.billingperiod, prod_homecare_actransactional_homecare.referralbilling
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  rb.*,
  bp.Name
FROM prod_homecare_actransactional_homecare.referralbilling AS rb
LEFT JOIN prod_homecare_actransactional_homecare.billingperiod AS bp
  ON bp.BillingPeriodID = rb.BillingPeriodID
WHERE
  ReportedOn >= '2022-02-01' AND Amount = 0
