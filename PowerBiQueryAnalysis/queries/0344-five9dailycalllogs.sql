-- Power BI query shape 344 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            19
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             30,007,921
-- Rows returned         9,990,620
-- Avg duration          271 ms
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
    agent,
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
  CASE
    WHEN AgentName = 'Leeba Sara Exito'
    THEN 'sarae'
    WHEN AgentName = 'Gregory Alsola'
    THEN 'grega'
    WHEN AgentName = 'Kate Cruz'
    THEN 'kate.cruz'
    WHEN AgentName = 'Rose Emilia'
    THEN 'roseem'
    ELSE LOWER(
      CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
    )
  END AS name_join,
  date,
  DATE_FORMAT(timestamp, 'HHmm') AS Time,
  TIMESTAMPDIFF(SECOND, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) AS CallGap
FROM CTE
