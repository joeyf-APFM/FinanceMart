-- Power BI query shape 377 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            8
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             0
-- Rows returned         0
-- Avg duration          107 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_import.five9dailycalllogs
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    calllogid,
    agentname,
    timestamp,
    LAG(timestamp) OVER (PARTITION BY agentname, CAST(timestamp AS DATE) ORDER BY timestamp) AS LagTimeStamp
  FROM prod_homecare_acreporting_import.five9dailycalllogs
  WHERE
    timestamp >= '2025' AND agentgroup = 'AC Care Advisors'
)
SELECT
  AgentName,
  CAST(timestamp AS DATE) AS Date,
  timestamp,
  calllogid,
  LagTimeStamp,
  TIMESTAMPDIFF(SECOND, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) AS CallGap,
  TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) AS CallGap
FROM CTE
