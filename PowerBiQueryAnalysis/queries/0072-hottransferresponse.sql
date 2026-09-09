-- Power BI query shape 72 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,197
-- Distinct texts        8 (same query, different literals or projection)
-- Rows read             8,630,569,989
-- Rows returned         121,905,523
-- Avg duration          2,630 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 498b5b81-ab8e-41ee-8683-f1b802ec8635, 6af1511e-31cf-4529-b5ce-58c26f7ebcc8
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
    HotTransferredOn >= '2025-01-01'
)
SELECT
  hmcrequestid,
  SUM(failed) AS HtAttempt,
  SUM(accepted) AS HtAcceptance
FROM CTE
GROUP BY
  hmcrequestid
