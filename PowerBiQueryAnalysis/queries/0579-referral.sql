-- Power BI query shape 579 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             13,893,192
-- Rows returned         586
-- Avg duration          784 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_seniorliving.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    ref.referralid,
    CAST(ref.referredon AS DATE) AS Referredon,
    hmcr.hmcrequestid,
    slpp.careadvisorcoordinator AS CA,
    LAG(CAST(ref.referredon AS DATE)) OVER (PARTITION BY hmcr.hmcrequestid ORDER BY ref.referredon DESC) AS lag
  FROM main.prod_homecare_actransactional_seniorliving.referral AS slpp
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = slpp.hmcrequestid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    NOT ref.hmcleadid IS NULL AND hmcr.createdate >= '2024'
), CTE1 AS (
  SELECT
    Referralid,
    referredon,
    lag,
    CASE WHEN lag IS NULL THEN 0 WHEN referredon = lag THEN 0 ELSE 1 END AS Additonal,
    CA
  FROM CTE
)
SELECT
  COUNT(DISTINCT referralid) AS Referrals,
  CA,
  ReferredOn
FROM CTE1
WHERE
  Additonal = 1
GROUP BY
  2,
  3
