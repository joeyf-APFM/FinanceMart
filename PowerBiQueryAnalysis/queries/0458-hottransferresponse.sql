-- Power BI query shape 458 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             0
-- Rows returned         0
-- Avg duration          210 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.lead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  HotTransferResultID,
  htr.ProviderID,
  lid.LeadID,
  htr.HotTransferResponseID,
  hs.name AS HotTransferResponse,
  CAST(r.referredon AS DATE) AS ReferralDate,
  r.providerid,
  p.warmtransferphonenumber,
  CONCAT(l.ContactFirstName, ' ', l.ContactLastName) AS ContactName,
  CONCAT(l.FirstName, ' ', l.LastName) AS ResidentName,
  l.ContactPhone,
  l.ContactEmail
FROM prod_homecare_actransactional_homecare.hottransferresult AS htr
LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
  ON l.LeadID = htr.LeadID
LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
  ON htr.ProviderID = r.ProviderID AND htr.LeadID = r.LeadID
LEFT JOIN prod_homecare_insite_directory.lead AS lid
  ON lid.HMCLeadID = r.HMCLeadID
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresponse AS hs
  ON hs.hottransferresponseid = htr.hottransferresponseid
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = r.providerid
WHERE
  r.referredon >= '2026-01-01'
