-- Power BI query shape 149 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            363
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             64,728,107
-- Rows returned         26,077,394
-- Avg duration          3,584 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_auth.users, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralnote
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ReferralNoteID,
  ReferralProcessStageID,
  rn.CreatedOn,
  rn.ReferralID,
  ref.ProviderID,
  LEFT(Notes, LOCATE(' -', Notes)) AS ReturnReason,
  RIGHT(Notes, LENGTH(Notes) - LOCATE('- ', Notes)) AS ReturnNote,
  u.FirstName,
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
WHERE
  rn.ReferralProcessStageID = 12 AND NOT ref.ReferralID IS NULL
