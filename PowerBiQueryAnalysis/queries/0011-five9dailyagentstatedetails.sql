-- Power BI query shape 11 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,967
-- Distinct texts        6 (same query, different literals or projection)
-- Rows read             11,549,231,413
-- Rows returned         12,189,620,223
-- Avg duration          21,730 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, a16a1e37-9a12-408d-ad05-9ea2571cb037, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  AgentStateDetailId,
  Agent,
  AgentGroup,
  AgentFirstName,
  AgentLastName,
  Time,
  LAG(Time) OVER (PARTITION BY Agent ORDER BY AgentStateDetailId DESC) AS EndTime,
  State,
  ReasonCode,
  MediaAvailability,
  SkillAvailability,
  CASE
    WHEN State = 'After Call Work' OR (
      State = 'Not Ready' AND ReasonCode = 'Quality'
    )
    THEN 'Wasted Time'
    ELSE ''
  END AS WastedTime,
  CASE
    WHEN State = 'Not Ready'
    AND (
      ReasonCode IN ('Out of Office', 'Lunch', 'Break', 'Away from Desk_SLA', 'Logout')
    )
    THEN 'Away'
    ELSE 'Working'
  END AS AgentStateGroup,
  AgentStateTime,
  DATE_FORMAT(Time, 'HH') AS hours,
  DATE_FORMAT(Time, 'mm') AS minute,
  (
    hours * 100
  ) + minute AS TimeID,
  detaildate,
  CASE
    WHEN Agent = 'leebasara.exito@aplaceformom.com'
    THEN 'sarae'
    WHEN Agent = 'gregory.alsola@aplaceformom.com'
    THEN 'grega'
    ELSE LOWER(
      CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
    )
  END AS name_join
FROM prod_homecare_acreporting_import.five9dailyagentstatedetails
WHERE
  detaildate >= '2025/01/01'
  AND agentstatetime <> '24:00:00'
  AND agentgroup = 'AC HCAM'
ORDER BY
  AgentStateDetailId DESC
