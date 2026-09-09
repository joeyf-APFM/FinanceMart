-- Power BI query shape 233 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             74,132,802
-- Rows returned         37,494,571
-- Avg duration          4,110 ms
-- Power BI datasets     none recorded
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
  CASE
    WHEN DAY(ReportedOn) >= 25
    THEN DATE_ADD(LAST_DAY(ADD_MONTHS(ReportedOn, 0)), 1)
    ELSE ReportedOn
  END AS ReportedOnMod,
  rb.InvoicedOn,
  rb.CreatedOn,
  rb.CreatedBy,
  bp.BillingPeriodID AS ActBillingPeriodID
FROM prod_homecare_actransactional_homecare.referralbilling AS rb
LEFT JOIN prod_homecare_actransactional_homecare.billingperiod AS bp
  ON (
    rb.InvoicedOn IS NULL AND bp.BillingPeriodStatusTypeID = 1
  )
  OR (
    rb.InvoicedOn = bp.InvoicedOn
  )
ORDER BY
  ReportedOn ASC
