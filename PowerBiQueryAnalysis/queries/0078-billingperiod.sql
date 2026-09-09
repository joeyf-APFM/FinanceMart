-- Power BI query shape 78 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,110
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             98,051,864
-- Rows returned         190,386,735
-- Avg duration          1,776 ms
-- Power BI datasets     a16a1e37-9a12-408d-ad05-9ea2571cb037
-- Tables                prod_homecare_actransactional_homecare.billingperiod, prod_homecare_actransactional_homecare.referralbilling
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ReferralBillingID,
  ReferralID,
  ProviderID,
  Amount,
  Rate,
  Amount * Rate / 100 AS RevShare,
  rb.BillingPeriodID,
  ReportedOn,
  rb.InvoicedOn,
  rb.CreatedOn,
  rb.CreatedBy,
  bp.BillingPeriodID AS ActBillingPeriodID,
  CASE WHEN bp.BillingPeriodID <> rb.BillingPeriodID THEN 0 ELSE 1 END AS Paid_On_Time
FROM prod_homecare_actransactional_homecare.referralbilling AS rb
LEFT JOIN prod_homecare_actransactional_homecare.billingperiod AS bp
  ON (
    rb.InvoicedOn IS NULL
    AND bp.BillingPeriodStatusTypeID = 1
    AND rb.reportedon >= DATE_ADD(TRUNC(ADD_MONTHS(CURRENT_DATE, -1), 'MM'), 24)
  )
  OR (
    rb.InvoicedOn = bp.InvoicedOn
  )
