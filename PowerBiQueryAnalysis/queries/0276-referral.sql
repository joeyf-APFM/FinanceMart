-- Power BI query shape 276 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            101
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             106,508,661
-- Rows returned         9,291,132
-- Avg duration          984 ms
-- Power BI datasets     981c2152-e626-4c9c-a7e3-c5876773579b
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.orderid,
  CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrder,
  ref.providerid,
  CASE WHEN ref.orderid = 3265 THEN 'Corporate Order' ELSE 'Individual Order' END AS OrderType,
  CAST(ref.referredon AS DATE) AS ReferralDate
FROM main.prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
WHERE
  p.providerorganizationid = 7
  AND ref.referredon >= '2025'
  AND ref.billingtypeid = 3
  AND NOT ref.hmcleadid IS NULL
