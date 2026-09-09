-- Power BI query shape 20 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,749
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             22,946,055,144
-- Rows returned         634,403,854
-- Avg duration          5,498 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.lead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  HotTransferResultID,
  htr.ProviderID,
  lid.LeadID,
  HotTransferResponseID,
  DATE_ADD(HOUR, -5, HotTransferredOn) AS HotTransferredOn,
  htr.CreatedOn,
  htr.CreatedBy,
  htr.ModifiedOn,
  htr.ModifiedBy,
  Deleted,
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
WHERE
  HotTransferredOn >= '2023-01-01'
