-- Power BI query shape 195 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            253
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,138,451,746
-- Rows returned         9,120,868
-- Avg duration          3,366 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ref.providerid,
  ref.orderid,
  CAST(ref.referredon AS DATE) AS ReferralDate,
  ref.referralid,
  CASE WHEN NOT htr.hottransferresponseid IS NULL THEN ref.referralid ELSE NULL END AS HotTransferAttempt,
  CASE WHEN htr.hottransferresponseid = 1 THEN ref.referralid ELSE NULL END AS HotTransferSuccess,
  htrr.name AS HotTransferResponse,
  htr.hottransferresponseid
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcleadid = ref.hmcleadid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresponse AS htrr
  ON htrr.hottransferresponseid = htr.hottransferresponseid
WHERE
  ref.referredon >= '2026'
  AND p.providerorganizationid = 123
  AND ref.billingtypeid = 3
  AND NOT ref.hmcleadid IS NULL
