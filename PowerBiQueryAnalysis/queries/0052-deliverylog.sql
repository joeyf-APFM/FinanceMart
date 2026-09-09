-- Power BI query shape 52 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,760
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             21,229,466,938
-- Rows returned         525,529,481
-- Avg duration          6,587 ms
-- Power BI datasets     b19514eb-b858-44d5-81a1-2c1a2e9f1483
-- Tables                prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.deliverystatustype, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
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
  r.orderid,
  log.DeliveryStatusTypeID,
  dst.Name AS DeliveryStatus
FROM prod_homecare_actransactional_homecare.referral AS r
LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
  ON r.LeadID = l.LeadID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.ProviderID = r.ProviderID
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
  ON r.ReferralID = log.ReferralID
LEFT JOIN prod_homecare_actransactional_homecare.deliverystatustype AS dst
  ON dst.deliverystatustypeid = log.deliverystatustypeid
WHERE
  NOT r.HMCLeadID IS NULL AND r.orderid = 2774 AND hmcr.createdate > '2023'
ORDER BY
  ReferredOn DESC
