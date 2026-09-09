-- Power BI query shape 179 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            274
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             62,255,997
-- Rows returned         20,359,362
-- Avg duration          3,016 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_auth.users, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralnote, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ReferralNoteID,
  ReferralProcessStageID,
  rn.CreatedOn,
  p.name AS ProviderName,
  rn.ReferralID,
  ref.ProviderID,
  LEFT(rn.Notes, LOCATE(' -', rn.Notes)) AS ReturnReason,
  RIGHT(rn.Notes, LENGTH(rn.Notes) - LOCATE('- ', rn.Notes)) AS ReturnNote,
  u.FirstName,
  po.name AS OrgName,
  digitaljourney
FROM prod_homecare_actransactional_homecare.referralnote AS rn
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
) AS ref
  ON ref.ReferralID = rn.ReferralID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON ref.providerid = p.ProviderID
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  rn.ReferralProcessStageID = 12 AND NOT ref.ReferralID IS NULL
