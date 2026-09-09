-- Power BI query shape 56 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,674
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             27,740,172,924
-- Rows returned         5,041,142,781
-- Avg duration          18,720 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  r.ReferralID,
  r.LeadID,
  l.HMCProspectID,
  hmcr.HMCRequestID,
  l.ExternalIdentifier AS YGL_Lead_ID,
  r.ProviderID,
  r.BillingTypeID,
  ReferralStatusTypeID,
  ReferredOn,
  r.activatedon,
  CAST(r.activatedon AS DATE) AS ActivatedOnDate,
  CASE WHEN NOT r.activatedon IS NULL THEN 1 ELSE 0 END AS Activations,
  CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
  CASE WHEN r.IsTopOff = 1 THEN 1 ELSE 0 END AS TopOffQueue,
  CASE
    WHEN r.AddOnTypeID = 1
    THEN 'AddOn'
    WHEN r.AddOnTypeID = 2
    THEN 'NeighborZip'
    WHEN r.AddOnTypeID = 3
    THEN 'ZipAddOn'
    ELSE NULL
  END AS AddOnType,
  CASE WHEN r.addontypeid IN (1, 2, 3) THEN 1 ELSE 0 END AS AddOn,
  r.CreatedOn,
  CAST(ReturnApproved AS INT),
  r.HMCLeadID,
  OrderID,
  r.digitaljourney,
  CASE WHEN p.IsPace = 1 THEN 1 ELSE 0 END AS PaceReferral,
  CAST(hcc.IsHotTransfer AS INT),
  hcc.Amount,
  CASE
    WHEN r.BillingTypeID = 1
    THEN 18
    WHEN hcc.AccountID = 2426
    AND log.DeliveryStatusTypeID IN (2, 3)
    AND hcc.CreatedOn >= '2024-11-06'
    AND hcc.IsHotTransfer = 0
    THEN 0
    WHEN hcc.AccountID = 2426
    AND hcc.Amount < 0
    AND hcc.CreatedOn >= '2024-11-22 21:33:00'
    AND hcc.IsHotTransfer = 0
    THEN hcc.Amount
    WHEN hcc.AccountID = 2426
    AND hcc.Amount > 0
    AND hcc.CreatedOn >= '2024-11-22 21:33:00'
    AND hcc.IsHotTransfer = 0
    THEN hcc.Amount
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
  AND hmcr.createdate > '2021'
ORDER BY
  ReferredOn DESC
