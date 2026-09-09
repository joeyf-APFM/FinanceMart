-- Power BI query shape 528 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             44,528,933
-- Rows returned         6,635,290
-- Avg duration          7,144 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcrequestphonenumber
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hmcr.hmcrequestid,
  hmcr.requeststatusid,
  CASE WHEN hmcp.disqualifier IS NULL THEN 0 ELSE 1 END AS Disqualifier,
  hmcr.createdate,
  CASE
    WHEN hmcp.hmcwhencareneededid = 1
    THEN 'Immediately'
    WHEN hmcp.hmcwhencareneededid = 2
    THEN 'Within 30 days'
    WHEN hmcp.hmcwhencareneededid = 3
    THEN 'Greater than 30 days'
    WHEN hmcp.hmcwhencareneededid = 4
    THEN 'Unsure'
    WHEN hmcp.hmcwhencareneededid = 5
    THEN 'Within 7 days'
    WHEN hmcp.hmcwhencareneededid = 6
    THEN 'No rush'
    ELSE NULL
  END AS WhenCareNeeded,
  CASE WHEN hmcp.hmcwhencareneededid IN (1, 2, 5) THEN 1 ELSE 0 END AS LessThan30Days,
  CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
  ref.ReferralID,
  ref.ReferredOn,
  ref.billingtypeid,
  ref.providerid,
  CAST(hcc.IsHotTransfer AS INT),
  p.Name AS ProviderName,
  po.name AS Org,
  ref.activatedon,
  CASE
    WHEN ref.activatedon <= DATE_ADD(WEEK, 1, ref.ReferredOn)
    THEN 1
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 1, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 2, ReferredOn)
    )
    THEN 2
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 2, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 3, ReferredOn)
    )
    THEN 3
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 3, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 4, ReferredOn)
    )
    THEN 4
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 4, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 5, ReferredOn)
    )
    THEN 5
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 5, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 6, ReferredOn)
    )
    THEN 6
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 6, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 7, ReferredOn)
    )
    THEN 7
    WHEN (
      ref.activatedon > DATE_ADD(WEEK, 7, ReferredOn)
      AND ref.activatedon <= DATE_ADD(WEEK, 8, ReferredOn)
    )
    THEN 8
    WHEN ref.activatedon > DATE_ADD(WEEK, 8, ReferredOn)
    THEN 9
    ELSE NULL
  END AS ToActivation,
  ref.returnapproved,
  YEAR(hmcr.createdate) AS Year
FROM prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN prod_homecare_insite_directory.hmcrequestphonenumber AS hmcrp
  ON hmcrp.hmcrequestid = hmcr.hmcrequestid
LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
  ON hmcp.hmcprospectid = hmcr.hmcprospectid
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = hmcl.hmcleadid
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
  ON hcc.ReferralID = ref.ReferralID AND hcc.IsCredit = 0
WHERE
  hmcr.createdate >= '2023'
  AND hmcr.createdate < DATE_ADD(YEAR, 1, DATE_TRUNC('YEAR', CURRENT_TIMESTAMP()))
