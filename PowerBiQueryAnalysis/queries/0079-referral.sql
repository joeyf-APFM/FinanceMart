-- Power BI query shape 79 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,110
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             4,163,322,793
-- Rows returned         4,167,299,839
-- Avg duration          4,557 ms
-- Power BI datasets     a16a1e37-9a12-408d-ad05-9ea2571cb037, af940fd5-99cd-4e93-a620-822230b10ce8, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ReferralID,
  LeadID,
  ProviderID,
  BillingTypeID,
  ReferralStatusTypeID,
  ReferredOn,
  ActivatedOn,
  StartedCareOn,
  EndedCareOn,
  ReturnApproved,
  HMCLeadID,
  OrderID,
  HMCLeadIDUpdateBy,
  ReferralDisplayStatusTypeID
FROM prod_homecare_actransactional_homecare.referral
