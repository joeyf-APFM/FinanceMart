-- Power BI query shape 12 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,966
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             26,449,245,764
-- Rows returned         56,231,095
-- Avg duration          9,943 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CONCAT(AgentFirstName, ' ', AgentLastName) AS AgentName,
    DATE_FORMAT(AgentStateTime, 'HH') AS Hour,
    DATE_FORMAT(AgentStateTime, 'mm') AS minutes,
    DATE_FORMAT(AgentStateTime, 'ss') AS seconds,
    agentstatetime,
    TO_DATE(detaildate, 'yyyy/MM/dd') AS DetailDate,
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
    detaildate >= '2024/01/01'
    AND agentstatetime <> '24:00:00'
    AND agentgroup = 'AC HCAM'
    AND NOT state IN ('Login', 'Logout')
  ORDER BY
    AgentStateDetailId DESC
), CTE1 AS (
  SELECT
    AgentName,
    DetailDate,
    Name_join,
    (
      hour * 3600
    ) + (
      minutes * 60
    ) + seconds AS Duration,
    agentstatetime
  FROM CTE
)
SELECT
  AgentName,
  DetailDate,
  Name_join,
  CASE
    WHEN SUM(duration) BETWEEN 0 AND 1800
    THEN '< 5 Hours'
    WHEN SUM(duration) BETWEEN 1801 AND 21600
    THEN '< 5-6 Hours'
    WHEN SUM(duration) BETWEEN 21601 AND 25200
    THEN '< 6-7 Hours'
    WHEN SUM(duration) BETWEEN 25201 AND 28800
    THEN '< 7-8 Hours'
    WHEN SUM(duration) BETWEEN 28801 AND 30600
    THEN '< 8-8.5 Hours'
    WHEN SUM(duration) > 30600
    THEN '>8.5'
    ELSE SUM(duration)
  END AS HoursWorked
FROM CTE1
GROUP BY
  AgentName,
  DetailDate,
  Name_join
