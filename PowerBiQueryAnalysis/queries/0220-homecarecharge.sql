-- Power BI query shape 220 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,276,055,973
-- Rows returned         499,545,286
-- Avg duration          9,320 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  r.ReferralID,
  r.LeadID,
  l.HMCProspectID,
  hmcr.HMCRequestID,
  l.ExternalIdentifier AS YGL_Lead_ID,
  ProviderID,
  BillingTypeID,
  ReferralStatusTypeID,
  ReferredOn,
  YEAR(ReferredOn) * 10000 + MONTH(ReferredOn) * 100 + DAY(ReferredOn) AS ReferredOnDateID,
  ActivatedOn,
  StartedCareOn,
  EndedCareOn,
  r.CreatedOn,
  ReturnApproved,
  r.HMCLeadID,
  OrderID,
  hcc.EntryID,
  hcc.Amount AS CPR_Revenue,
  CASE WHEN r.OrderID = 2774 THEN 34 ELSE hcc.Amount END AS CPL_Revenue,
  COUNT(*) OVER (PARTITION BY r.ReferralID ORDER BY r.HMCLeadID DESC) AS ct
FROM prod_homecare_actransactional_homecare.referral AS r
LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
  ON r.LeadID = l.LeadID
LEFT JOIN (
  SELECT
    HomeCareChargeID,
    AccountID,
    ReferralID,
    Amount,
    IsCredit,
    CreatedOn,
    EntryID,
    ROW_NUMBER() OVER (PARTITION BY ReferralID ORDER BY CreatedOn DESC) AS rn
  FROM prod_homecare_actransactional_billing.homecarecharge
  WHERE
    IsCredit = 0
) AS hcc
  ON hcc.ReferralID = r.ReferralID AND rn = 1
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.HMCLeadID = r.HMCLeadID
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcl.HMCRequestID = hmcr.HMCRequestID
WHERE
  1 = 1
  AND (
    (
      BillingTypeID = 3 AND NOT r.HMCLeadID IS NULL
    )
  )
  AND r.ReferredOn > '2021'
ORDER BY
  ReferralID DESC
