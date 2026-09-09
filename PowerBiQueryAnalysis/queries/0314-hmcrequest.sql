-- Power BI query shape 314 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            40
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             239,231,821
-- Rows returned         149,398,786
-- Avg duration          6,619 ms
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
  NOT sr.outcomeid IN (15, 13, 22, 24)
  AND req.createdate >= DATE_ADD(YEAR, -1, DATE_TRUNC('MONTH', CURRENT_TIMESTAMP()))
  AND req.hmcrequestid <> 9
