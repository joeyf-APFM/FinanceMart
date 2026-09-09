-- Power BI query shape 208 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            241
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,472,536,802
-- Rows returned         446,078
-- Avg duration          34,693 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ref.providerid,
    ref.orderid,
    CAST(ref.activatedon AS DATE) AS ActivationDate,
    ref.referralid,
    hmcl.hmcrequestid,
    CASE WHEN NOT ref.activatedon IS NULL THEN ref.referralid ELSE NULL END AS Activation
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  WHERE
    ref.activatedon >= '2026'
    AND p.providerorganizationid = 123
    AND ref.billingtypeid = 3
    AND NOT ref.hmcleadid IS NULL
), CTEA AS (
  SELECT
    CTE.HMCRequestID,
    CTE.Referralid,
    ref.referralid AS NewReferralid,
    ref.activatedon,
    cte.providerid,
    ref.providerid
  FROM CTE
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = cte.hmcrequestid
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    ref.activatedon >= '2026'
    AND ref.billingtypeid = 3
    AND NOT ref.activatedon IS NULL
    AND ref.referralid <> cte.referralid
)
SELECT
  CTE.ProviderID,
  CTE.OrderID,
  CTE.activationdate,
  CTE.ReferralID,
  CTE.Activation,
  CTEA.NewReferralid AS Missed_Activation
FROM CTE
LEFT JOIN CTEA
  ON CTEA.hmcrequestid = cte.hmcrequestid
