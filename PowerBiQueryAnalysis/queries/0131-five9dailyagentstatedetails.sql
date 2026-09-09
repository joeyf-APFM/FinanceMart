-- Power BI query shape 131 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            424
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             4,494,598,088
-- Rows returned         4,481,012,420
-- Avg duration          33,749 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
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
  TO_DATE(detaildate, 'yyyy/MM/dd') >= DATE_ADD(MONTH, -5, CURRENT_DATE)
  AND agentstatetime <> '24:00:00'
ORDER BY
  AgentStateDetailId DESC
