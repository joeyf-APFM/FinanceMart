-- Power BI query shape 324 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            30
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             129,788,630
-- Rows returned         7,255,224
-- Avg duration          2,119 ms
-- Power BI datasets     6f367367-19b7-4314-b324-b8f6a041aa2e
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralreturnrequest, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ref.referralid,
  CAST(ref.referredon AS DATE) AS Referredon,
  ref.providerid,
  rr.returnapproved,
  CAST(rr.createdon AS DATE) AS ReturnCreateDate,
  hcc.homecarechargeid,
  hcc.amount,
  p.providerorganizationid,
  CAST(hcc.createdon AS DATE) AS ChargeCreateDate
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_homecare.referralreturnrequest AS rr
  ON rr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_billing.homecarecharge AS hcc
  ON hcc.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON ref.providerid = p.providerid
WHERE
  NOT ref.hmcleadid IS NULL
  AND ref.billingtypeid = 3
  AND ref.referredon >= '2025'
  AND (
    p.providerorganizationid IN (1, 2, 3, 71, 101, 112, 117, 123, 122, 128)
    OR LOWER(p.name) LIKE 'housework%'
  )
