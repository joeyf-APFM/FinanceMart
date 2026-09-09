-- Power BI query shape 92 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            933
-- Distinct texts        9 (same query, different literals or projection)
-- Rows read             9,010,198,985
-- Rows returned         6,066,933,910
-- Avg duration          8,611 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
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
  sr.HMCRequestID,
  req.requeststatusid
/*  ,req.affiliateid */
FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON req.HMCRequestID = sr.HMCRequestID
WHERE
  NOT sr.outcomeid IN (15, 13, 22, 24) AND req.createdate >= '2025-01-01'
