-- Power BI query shape 378 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            8
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             264,488
-- Rows returned         8,000
-- Avg duration          208 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.providerid,
  htr.hottransferresponseid,
  hr.name AS HotTransferResponse
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresponse AS hr
  ON hr.hottransferresponseid = htr.hottransferresponseid
WHERE
  p.providerorganizationid = 117 AND ref.referredon >= '2025'
