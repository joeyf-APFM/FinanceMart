-- Power BI query shape 99 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            861
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,447,340,301
-- Rows returned         60,580,989
-- Avg duration          2,657 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralnote
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ref.referralid,
  ref.referredon,
  ref.providerid,
  returnapproved,
  ref.modifiedon,
  rn.createdon AS ReturnApprovedDate,
  referralprocessstageid
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN prod_homecare_actransactional_homecare.referralnote AS rn
  ON rn.referralid = ref.referralid
WHERE
  referralprocessstageid = 12
  AND ref.referredon >= '2024'
  AND NOT ref.hmcleadid IS NULL
  AND ref.billingtypeid = 3
