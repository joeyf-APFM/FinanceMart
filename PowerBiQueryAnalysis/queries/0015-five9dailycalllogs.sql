-- Power BI query shape 15 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,954
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             1,783,263,046
-- Rows returned         35,303,426
-- Avg duration          2,076 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
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
    timestamp >= '2025' AND agentgroup = 'AC HCAM'
), CTE1 AS (
  SELECT
    AgentName,
    CAST(timestamp AS DATE) AS Date,
    timestamp,
    calllogid,
    LagTimeStamp,
    TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) AS Holder,
    CASE
      WHEN TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) < 10
      THEN 'Call Gaps < 10 Min'
      WHEN TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) BETWEEN 10 AND 30
      THEN 'Call Gaps 10 -30 Min'
      WHEN TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) BETWEEN 31 AND 60
      THEN 'Call Gaps 30 -60 Min'
      WHEN TIMESTAMPDIFF(MINUTE, CAST(LagTimeStamp AS TIMESTAMP), Timestamp) > 60
      THEN 'Call Gaps > 60'
      ELSE NULL
    END AS CallGapBucket
  FROM CTE
)
SELECT
  Date,
  Agentname,
  MAX(Holder) AS Max_Gap,
  ROUND(PERCENTILE(holder, 0.9), 2) AS NinetyPercentile
FROM CTE1
WHERE
  NOT callgapbucket IS NULL
GROUP BY
  Date,
  AgentName
ORDER BY
  Date,
  Agentname
