-- Power BI query shape 404 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,579,420
-- Rows returned         32,014
-- Avg duration          327 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.providerid,
  p.name AS ProviderName,
  ref.orderid,
  ref.referralid,
  CAST(referredon AS DATE) AS ReferralDate,
  CAST(ref.activatedon AS DATE) AS ActivatedOnDate,
  hcc.amount,
  CASE WHEN htr.hottransferresponseid = 1 THEN ref.referralid ELSE NULL END AS HotTransferred,
  CASE WHEN ref.returnapproved = TRUE THEN ref.referralid ELSE NULL END AS Returns,
  hcc.iscredit
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_billing.homecarecharge AS hcc
  ON hcc.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = ref.orderid
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
WHERE
  NOT ref.hmcleadid IS NULL
  AND ref.billingtypeid = 3
  AND p.providerorganizationid = 123
  AND ref.referredon >= '2026-01-01'
ORDER BY
  ref.providerid,
  ref.orderid,
  ref.referredon,
  ref.referralid
