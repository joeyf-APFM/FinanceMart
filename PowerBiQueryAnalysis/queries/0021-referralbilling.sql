-- Power BI query shape 21 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,741
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             20,241,602
-- Rows returned         68,665,177
-- Avg duration          667 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.referralbilling
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
  BillingPeriodID,
  ReportedOn,
  InvoicedOn,
  ModifiedOn,
  ModifiedBy,
  CreatedOn,
  CreatedBy,
  SysStartTime,
  SysEndTime
FROM prod_homecare_actransactional_homecare.referralbilling
WHERE
  InvoicedOn >= '2023-01-01' OR InvoicedOn IS NULL
