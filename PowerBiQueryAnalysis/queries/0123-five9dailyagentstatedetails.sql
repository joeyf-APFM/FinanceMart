-- Power BI query shape 123 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            488
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             9,739,643,525
-- Rows returned         10,076,408,762
-- Avg duration          48,262 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  AgentStateDetailId,
  Agent,
  AgentGroup,
  DATE_FORMAT(Time, 'HHmm') AS Timeid,
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
  TO_DATE(detaildate, 'yyyy/MM/dd') >= '2025-06-01'
  AND agentstatetime <> '24:00:00'
  AND AgentGroup = 'AC Care Advisors'
ORDER BY
  AgentStateDetailId DESC
