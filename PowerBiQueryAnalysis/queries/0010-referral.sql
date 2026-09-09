-- Power BI query shape 10 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,971
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             4,881,580,714
-- Rows returned         2,169,359,585
-- Avg duration          2,093 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  COUNT(DISTINCT ref.referralid) AS Referrals,
  ref.orderid,
  CAST(ref.referredon AS DATE) AS ReferralDate
FROM prod_homecare_actransactional_homecare.referral AS ref
WHERE
  NOT ref.hmcleadid IS NULL AND ref.referredon >= '2024'
GROUP BY
  ref.orderid,
  CAST(ref.referredon AS DATE)
