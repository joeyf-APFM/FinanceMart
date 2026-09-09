-- Power BI query shape 622 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             716,903
-- Rows returned         404,358
-- Avg duration          3,734 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  COUNT(DISTINCT referralid) AS Referrals,
  providerid,
  CAST(referredon AS DATE) AS Referredon
FROM prod_homecare_actransactional_homecare.referral AS ref
WHERE
  NOT hmcleadid IS NULL AND ref.referredon >= '2025' AND billingtypeid = 3
GROUP BY
  2,
  3
