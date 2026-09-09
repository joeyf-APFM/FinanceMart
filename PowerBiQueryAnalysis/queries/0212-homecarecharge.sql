-- Power BI query shape 212 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,102,931,140
-- Rows returned         47,823,946
-- Avg duration          9,691 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
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
  r.ProviderID,
  r.BillingTypeID,
  ReferralStatusTypeID,
  ReferredOn,
  CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
  CASE WHEN r.IsTopOff = 1 THEN 1 ELSE 0 END AS TopOffQueue,
  CAST(r.CreatedOn AS DATE) AS Createdon,
  ReturnApproved,
  r.HMCLeadID,
  OrderID,
  CASE WHEN p.IsPace = 1 THEN 1 ELSE 0 END AS PaceReferral,
  hcc.IsHotTransfer,
  hcc.Amount,
  CASE
    WHEN r.BillingTypeID = 1
    THEN 18
    WHEN hcc.AccountID = 2426
    AND log.DeliveryStatusTypeID IN (2, 3)
    AND hcc.CreatedOn >= '2024'
    AND hcc.IsHotTransfer = 0
    THEN -42
    WHEN hcc.AccountID = 2426
    AND hcc.Amount < 0
    AND hcc.CreatedOn >= '2024'
    AND hcc.IsHotTransfer = 0
    THEN -42
    WHEN hcc.AccountID = 2426
    AND hcc.Amount > 0
    AND hcc.CreatedOn >= '2024'
    AND hcc.IsHotTransfer = 0
    THEN 42
    WHEN hcc.AccountID = 2426 AND hcc.Amount < 0 AND hcc.IsHotTransfer = 0
    THEN -34
    WHEN hcc.AccountID = 2426 AND hcc.Amount > 0 AND hcc.IsHotTransfer = 0
    THEN 34
    WHEN hcc.AccountID = 2426 AND hcc.IsHotTransfer = 1
    THEN 0
    ELSE hcc.Amount
  END AS ReferralRevenue
FROM prod_homecare_actransactional_homecare.referral AS r
LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
  ON r.LeadID = l.LeadID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.ProviderID = r.ProviderID
LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
  ON hcc.ReferralID = r.ReferralID AND hcc.IsCredit = 0
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.HMCLeadID = r.HMCLeadID
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcl.HMCRequestID = hmcr.HMCRequestID
LEFT JOIN (
  SELECT
    DeliveryLogID,
    DeliveryName,
    ReferralID,
    DeliveryStatusTypeID
  FROM prod_homecare_actransactional_homecare.deliverylog
  WHERE
    DeliveryName = 'HomeInsteadProvider'
) AS log
  ON hcc.ReferralID = log.ReferralID
WHERE
  1 = 1
  AND /* AND BillingTypeID = 3 */ NOT r.HMCLeadID IS NULL
  AND hmcr.createdate > DATE_ADD(MONTH, -3, CURRENT_TIMESTAMP())
ORDER BY
  ReferredOn DESC
