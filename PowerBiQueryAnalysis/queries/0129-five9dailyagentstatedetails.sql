-- Power BI query shape 129 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            456
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             8,213,782,793
-- Rows returned         9,460,005,541
-- Avg duration          40,414 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  AgentStateDetailId,
  Agent,
  AgentGroup,
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
  DetailDate,
  CASE
    WHEN Agent = 'leebasara.exito@aplaceformom.com'
    THEN 'sarae'
    WHEN Agent = 'kate.cruz@aplaceformom.com'
    THEN 'kate.cruz'
    WHEN Agent = 'gregory.alsola@aplaceformom.com'
    THEN 'grega'
    WHEN Agent = 'rose.emilia@aplaceformom.com'
    THEN 'roseem'
    ELSE LOWER(
      CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
    )
  END AS name_join
FROM prod_homecare_acreporting_import.five9dailyagentstatedetails
WHERE
  TO_DATE(detaildate, 'yyyy/MM/dd') >= '2025'
  AND agentstatetime <> '24:00:00'
  AND AgentGroup = 'AC Care Advisors'
ORDER BY
  AgentStateDetailId DESC
