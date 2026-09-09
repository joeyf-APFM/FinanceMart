-- Power BI query shape 164 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            297
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             520,650,635
-- Rows returned         173,611,316
-- Avg duration          2,124 ms
-- Power BI datasets     c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.providerid,
  ref.orderid,
  CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrder,
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
