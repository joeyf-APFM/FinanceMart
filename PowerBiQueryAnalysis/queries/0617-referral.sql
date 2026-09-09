-- Power BI query shape 617 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             24,790,356
-- Rows returned         2,823
-- Avg duration          1,486 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_seniorliving.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    slpp.hmcrequestid,
    CAST(slpp.referraldate AS DATE) AS SLPPReferralDate,
    slpp.careadvisorcoordinator AS CA,
    hmcr.hmcprospectid,
    CAST(hmcr.createdate AS DATE) AS SLPPLeadCreateDate,
    req.createdate,
    ref.referralid,
    ref.referredon,
    req.hmcrequestid AS AdditonalReq
  FROM main.prod_homecare_actransactional_seniorliving.referral AS slpp
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = slpp.hmcrequestid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS req
    ON req.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = req.hmcrequestid
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    req.createdate > slpp.referraldate AND NOT ref.referralid IS NULL
)
SELECT
  CA,
  SLPPReferralDate,
  COUNT(DISTINCT AdditonalReq) AS AdditonalLeads,
  COUNT(DISTINCT referralid) AS AdditonalRef
FROM CTE
GROUP BY
  1,
  2
