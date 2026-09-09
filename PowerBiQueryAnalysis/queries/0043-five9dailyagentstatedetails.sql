-- Power BI query shape 43 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,060
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             58,261,009,676
-- Rows returned         184,958,126,486
-- Avg duration          80,434 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_import.five9dailyagentstatedetails, prod_homecare_acreporting_import.five9dailycalllogs
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    Detaildate,
    State,
    Time,
    agentfirstname,
    agent,
    agentlastname,
    DATE_FORMAT(Time, 'HH') AS hours,
    DATE_FORMAT(Time, 'mm') AS minute,
    ROW_NUMBER() OVER (PARTITION BY detaildate, agentfirstname ORDER BY Time) AS rn,
    (
      hours * 100
    ) + minute AS TimeID,
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
    TIME <> '12:00:00'
    AND TIME <> '00:00:00'
    AND State = 'Login'
    AND agentstatetime <> '24:00:00'
    AND agentgroup = 'AC HCAM'
    AND TO_DATE(detaildate, 'yyyy/MM/dd') >= '2025'
), CTE1 AS (
  SELECT
    *
  FROM CTE
  WHERE
    rn = 1
)
SELECT DISTINCT
  callid,
  CTE1.Time AS First_LogIn,
  sd.agent,
  sd.detaildate AS Date,
  DATE_FORMAT(sd.Time, 'HH') AS hours,
  DATE_FORMAT(sd.Time, 'mm') AS minute,
  (
    hours * 100
  ) + minute AS TimeID,
  sd.detaildate,
  CASE
    WHEN sd.Agent = 'leebasara.exito@aplaceformom.com'
    THEN 'sarae'
    WHEN sd.Agent = 'gregory.alsola@aplaceformom.com'
    THEN 'grega'
    ELSE LOWER(
      CONCAT(
        LEFT(sd.Agent, LOCATE('.', sd.Agent) - 1),
        SUBSTRING(sd.Agent, LOCATE('.', sd.Agent) + 1, 1)
      )
    )
  END AS name_join
FROM prod_homecare_acreporting_import.five9dailyagentstatedetails AS sd
JOIN CTE1
  ON CTE1.detaildate = sd.Detaildate AND CTE1.agent = sd.agent
JOIN prod_homecare_acreporting_import.five9dailycalllogs AS f9
  ON CAST(f9.timestamp AS DATE) = TO_DATE(sd.detaildate, 'yyyy/MM/dd')
  AND f9.agent = sd.agent
WHERE
  sd.detaildate >= '2025/01/01'
  AND sd.agentstatetime <> '24:00:00'
  AND sd.agentgroup = 'AC HCAM'
