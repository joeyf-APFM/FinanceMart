-- Power BI query shape 13 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,963
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             497,262,947
-- Rows returned         564,544,094
-- Avg duration          105,777 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails, prod_homecare_acreporting_reporting.dimdate, prod_homecare_acreporting_reporting.dimtime
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    AgentStateDetailId,
    Agent,
    AgentGroup,
    AgentFirstName,
    AgentLastName,
    Time,
    State,
    SECOND(agentstatetime) + (
      MINUTE(agentstatetime) * 60
    ) AS Duration,
    ReasonCode,
    AgentStateTime,
    DATE_FORMAT(Time, 'HH') AS hours,
    DATE_FORMAT(Time, 'mm') AS minute,
    (
      hours * 100
    ) + minute AS StartTimeID,
    DATE_FORMAT(TO_DATE(detaildate, 'yyyy/MM/dd'), 'yyyyMMdd') AS DateID,
    TO_DATE(detaildate, 'yyyy/MM/dd') AS Date,
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
    (
      MONTH(TO_DATE(detaildate, 'yyyy/MM/dd')) >= MONTH(ADD_MONTHS(DATE_TRUNC('MM', CURRENT_TIMESTAMP()), -1))
    )
    AND YEAR(TO_DATE(detaildate, 'yyyy/MM/dd')) = YEAR(CURRENT_TIMESTAMP())
    AND agentstatetime <> '24:00:00'
    AND agentgroup = 'AC HCAM'
    AND state = 'On Call'
  ORDER BY
    AgentStateDetailId DESC
), CTEA AS (
  SELECT
    dateid AS TimeDateID,
    date AS DimDate,
    month,
    year,
    timeid AS DimTimeID,
    time,
    monthyearid,
    monthname,
    CONCAT(dateid, timeid) AS DateTimeID
  FROM prod_homecare_acreporting_reporting.dimdate
  CROSS JOIN prod_homecare_acreporting_reporting.dimtime
  WHERE
    date >= '2025-03-01'
  ORDER BY
    date,
    timeid
), CTE1 AS (
  SELECT
    CTEA.TimeDateID,
    CTEA.DimDate,
    CTEA.DimTimeID,
    CTEA.MonthName,
    CTEA.MonthYearID,
    CTEA.DateTimeID,
    DATE_FORMAT(DATE_ADD(SECOND, duration, cte.time), 'Hmm') AS EndTimeID,
    CTE.*
  FROM cte
  LEFT JOIN CTEA
    ON CTEA.TimeDateID = CTE.DateID
), CTE2 AS (
  SELECT
    CASE
      WHEN (
        DimTimeID >= StartTimeID AND DimTimeID <= EndTimeID
      )
      THEN 1
      ELSE 0
    END AS OnCall,
    CTE1.*
  FROM CTE1
  ORDER BY
    DimDate,
    DimTimeID,
    Agent
)
SELECT
  *
FROM CTE2
WHERE
  oncall = 1
