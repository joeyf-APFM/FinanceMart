-- Power BI query shape 110 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            593
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             3,092,298,859
-- Rows returned         85,956,379
-- Avg duration          6,018 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, a16a1e37-9a12-408d-ad05-9ea2571cb037, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_auth.users, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralnote, prod_homecare_actransactional_homecare.referralreturnprimaryreasontype, prod_homecare_actransactional_homecare.referralreturnrequest, prod_homecare_actransactional_homecare.referralreturnsecondaryreasontype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  rn.ReferralNoteID,
  rn.ReferralProcessStageID,
  rn.CreatedOn,
  p.name AS ProviderName,
  rn.ReferralID,
  r.ProviderID,
  CASE
    WHEN ref.referredon <= '2025-06-23'
    THEN LEFT(rn.Notes, LOCATE(' -', rn.Notes))
    ELSE rsrt.name
  END AS ReturnReason,
  RIGHT(rn.Notes, LENGTH(rn.Notes) - LOCATE('- ', rn.Notes)) AS ReturnNote,
  u.FirstName,
  po.name AS OrgName,
  r.digitaljourney
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN prod_homecare_actransactional_homecare.referralnote AS rn
  ON ref.referralid = rn.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.referralreturnrequest AS rr
  ON rr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.referralreturnprimaryreasontype AS rprt
  ON rprt.referralreturnprimaryreasontypeid = rr.PrimaryReasonTypeID
LEFT JOIN main.prod_homecare_actransactional_homecare.referralreturnsecondaryreasontype AS rsrt
  ON rsrt.referralreturnsecondaryreasontypeid = rr.SecondaryReasonTypeID
LEFT JOIN prod_homecare_actransactional_auth.users AS u
  ON u.UserID = rn.CreatedBy
LEFT JOIN (
  SELECT
    ReferralID,
    digitaljourney,
    ProviderID
  FROM prod_homecare_actransactional_homecare.referral
  WHERE
    ReturnApproved = 1 AND BillingTypeID = 3 AND ReferredOn >= '2023-01-01'
) AS r
  ON r.ReferralID = rn.ReferralID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON r.providerid = p.ProviderID
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  (
    rn.ReferralProcessStageID = 12 OR rr.returnapproved = TRUE
  )
  AND NOT ref.ReferralID IS NULL
