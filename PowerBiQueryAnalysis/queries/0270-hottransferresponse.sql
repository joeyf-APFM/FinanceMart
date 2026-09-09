-- Power BI query shape 270 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            103
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             858,719,399
-- Rows returned         5,316,934
-- Avg duration          3,585 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcl.HMCRequestID,
    HotTransferResultID,
    (
      CASE
        WHEN htrs.name LIKE '%Failed%'
        THEN 1
        WHEN htrs.name LIKE '%Denied%'
        THEN 1
        ELSE 0
      END
    ) AS Failed,
    (
      CASE WHEN htrs.name LIKE '%Accept%' THEN 1 ELSE 0 END
    ) AS Accepted
  FROM prod_homecare_actransactional_homecare.hottransferresult AS htr
  LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
    ON r.LeadID = htr.LeadID
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.HMCLeadID = r.HMCLeadID
  LEFT JOIN prod_homecare_actransactional_homecare.hottransferresponse AS htrs
    ON htrs.hottransferresponseid = htr.hottransferresponseid
  WHERE
    HotTransferredOn >= DATE_ADD(MONTH, -12, CURRENT_TIMESTAMP())
)
SELECT
  hmcrequestid,
  SUM(failed) AS HtAttempt,
  SUM(accepted) AS HtAcceptance
FROM CTE
GROUP BY
  hmcrequestid
