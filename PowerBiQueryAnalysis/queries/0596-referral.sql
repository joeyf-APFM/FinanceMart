-- Power BI query shape 596 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,492,448
-- Rows returned         496,180
-- Avg duration          900 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.providerid,
  ref.orderid,
  CASE WHEN ref.returnapproved = TRUE THEN 1 ELSE 0 END AS ReturnApproved,
  CAST(ref.referredon AS DATE) AS ReferredOn,
  CAST(ref.activatedon AS DATE) AS ActivatedOn
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
WHERE
  ref.referredon >= '2024'
  AND ref.billingtypeid = 3
  AND p.providerorganizationid IS NULL
