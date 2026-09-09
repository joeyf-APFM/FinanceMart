-- Power BI query shape 267 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            103
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             75,145,230
-- Rows returned         75,142,134
-- Avg duration          3,852 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_insite_directory.hmccallbackresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  HMCCallBackResultID,
  HMCProspectID,
  createdate,
  outcomeid,
  userid,
  AttemptCount,
  FollowUpDate,
  SecondsInProspect,
  HMCRequestID,
  HMCCallBackReason
FROM prod_homecare_insite_directory.hmccallbackresult
WHERE
  createdate >= DATE_ADD(MONTH, -6, CURRENT_TIMESTAMP())
