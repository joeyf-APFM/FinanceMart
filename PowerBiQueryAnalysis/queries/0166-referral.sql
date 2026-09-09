-- Power BI query shape 166 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            295
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,086,799,786
-- Rows returned         13,645,770
-- Avg duration          3,533 ms
-- Power BI datasets     c38af845-cf82-47a4-9373-12845eb51d16
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcrequestid,
    ref.referralid,
    ref.providerid,
    CAST(ref.referredon AS DATE) AS ReferralDate,
    ref.returnapproved,
    ref.activatedon,
    CASE WHEN NOT ref.activatedon IS NULL THEN 'Yes' ELSE 'No' END AS Activation
  FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    p.providerorganizationid = 117 AND ref.referredon >= '2025'
), CTEA AS (
  SELECT
    CTE.hmcrequestid,
    Ref.referralid
  FROM CTE
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = cte.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    p.providerorganizationid <> 117 AND NOT ref.activatedon IS NULL
)
SELECT
  CTE.HMCRequestID,
  CTE.Referralid,
  CTE.ProviderID,
  CTE.ReferralDate,
  CTE.ReturnApproved,
  CTE.ActivatedOn,
  CTE.Activation,
  CTEA.referralid AS MissedConversion
FROM CTE
LEFT JOIN CTEA
  ON CTEA.hmcrequestid = CTE.hmcrequestid
