-- Power BI query shape 125 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            479
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             8,021,729,750
-- Rows returned         4,700,964,130
-- Avg duration          34,226 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CASE WHEN state IN ('Ringing', 'On Call') THEN 'On Call' ELSE 'Ready' END AS UpdatedStatus,
    *,
    (
      DATE_FORMAT(CAST(agentstatetime AS TIMESTAMP), 'mm') * 60
    ) + (
      DATE_FORMAT(CAST(agentstatetime AS TIMESTAMP), 'ss')
    ) AS Duration,
    CASE
      WHEN CONCAT(agentfirstname, ' ', agentlastname) = 'Leeba Sara Exito'
      THEN 'sarae'
      WHEN CONCAT(agentfirstname, ' ', agentlastname) = 'Gregory Alsola'
      THEN 'grega'
      WHEN CONCAT(agentfirstname, ' ', agentlastname) = 'Kate Cruz'
      THEN 'kate.cruz'
      WHEN CONCAT(agentfirstname, ' ', agentlastname) = 'Rose Emilia'
      THEN 'roseem'
      ELSE LOWER(
        CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
      )
    END AS name_join
  FROM main.prod_homecare_acreporting_import.five9dailyagentstatedetails
  WHERE
    TO_DATE(detaildate, 'yyyy/MM/dd') >= '2025-06-01'
    AND agentgroup = 'AC Care Advisors'
    AND /* and agent = ('abner.pontino@aplaceformom.com') */ NOT state IN ('Logout', 'Login')
    AND agentstatetime <> '00:00:00'
    AND (
      NOT reasoncode IN ('Lunch', 'Meeting', 'Break', 'Tech Issues')
      OR reasoncode IS NULL
    )
  ORDER BY
    detaildate,
    time
), CTE1 AS (
  SELECT
    TO_DATE(detaildate, 'yyyy/MM/dd') AS Date,
    Time,
    agentstatetime,
    agent,
    updatedstatus,
    duration,
    name_join,
    IF(
      LAG(updatedstatus) OVER (PARTITION BY detaildate, agent ORDER BY TO_DATE(detaildate, 'yyyy/MM/dd'), time) IS NULL,
      updatedstatus,
      LAG(updatedstatus) OVER (PARTITION BY detaildate, agent ORDER BY TO_DATE(detaildate, 'yyyy/MM/dd'), time)
    ) AS prev_value
  FROM CTE
), flags AS (
  SELECT
    Date,
    time,
    agentstatetime,
    agent,
    updatedstatus,
    duration,
    name_join,
    CASE WHEN updatedstatus = prev_value THEN 0 ELSE 1 END AS is_new
  FROM cte1
), CTE2 AS (
  SELECT
    Date,
    time,
    agentstatetime,
    agent,
    updatedstatus,
    duration,
    name_join,
    SUM(is_new) OVER (PARTITION BY date, agent ORDER BY date, time) AS group_id
  FROM flags
)
SELECT
  Agent,
  Date,
  name_join,
  Group_id,
  updatedstatus,
  MIN(time) AS FirstTime,
  SUM(duration) AS TotalTime
FROM CTE2
GROUP BY
  1,
  2,
  3,
  4,
  5
