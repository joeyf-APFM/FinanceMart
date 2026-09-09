-- Power BI query shape 168 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            293
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             451,824,407
-- Rows returned         1,393,129
-- Avg duration          2,511 ms
-- Power BI datasets     c38af845-cf82-47a4-9373-12845eb51d16
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.providerid,
  htr.hottransferresponseid,
  hr.name AS HotTransferResponse,
  CAST(hottransferredon AS DATE) AS HotTransferredOn
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresponse AS hr
  ON hr.hottransferresponseid = htr.hottransferresponseid
WHERE
  p.providerorganizationid = 117
  AND ref.referredon >= '2025'
  AND NOT hottransferredon IS NULL
