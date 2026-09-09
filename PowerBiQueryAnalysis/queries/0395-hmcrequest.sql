-- Power BI query shape 395 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        6 (same query, different literals or projection)
-- Rows read             31,699,796
-- Rows returned         12,572,350
-- Avg duration          1,786 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  sr.HMCScreeningResultID, /*  ,sr.HMCProspectID */
  sr.createdate,
  sr.outcomeid,
  sr.userid,
  req.createdate AS RequestDate,
  sr.AttemptCount, /*  ,sr.FollowUpDate */ /*  ,sr.HotTransferred */
  sr.SecondsInProspect,
  sr.HMCRequestID
/*  ,req.affiliateid */
FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON req.HMCRequestID = sr.HMCRequestID
WHERE
  NOT sr.outcomeid IN (15, 13, 1, 2) AND req.createdate >= '2024-01-01'
