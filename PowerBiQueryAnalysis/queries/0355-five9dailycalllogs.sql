-- Power BI query shape 355 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            14
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             12,173,886
-- Rows returned         6,099,943
-- Avg duration          207 ms
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
  date,
  DATE_FORMAT(timestamp, 'HHmm') AS Time,
  TIMESTAMPDIFF(SECOND, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) AS CallGap
FROM CTE
