-- Power BI query shape 272 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            103
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             311,162,320
-- Rows returned         177,272,363
-- Avg duration          5,702 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  sr.HMCScreeningResultID,
  sr.HMCProspectID,
  sr.createdate,
  sr.outcomeid,
  sr.userid,
  req.createdate AS RequestDate,
  sr.AttemptCount,
  sr.FollowUpDate,
  sr.HotTransferred,
  sr.SecondsInProspect,
  sr.HMCRequestID,
  req.affiliateid
FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON req.HMCRequestID = sr.HMCRequestID
WHERE
  NOT sr.outcomeid IN (15, 13, 1, 2)
  AND req.createdate >= DATE_ADD(MONTH, -6, CURRENT_TIMESTAMP())
