-- Power BI query shape 80 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,091
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             37,308,868,595
-- Rows returned         822,944,198
-- Avg duration          17,210 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_import.five9dailycalllogs
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CallId,
    SUM(CASE WHEN CallType = '3rd party conference' THEN 1 ELSE 0 END) AS Transfers_Attempted
  FROM prod_homecare_acreporting_import.five9dailycalllogs
  GROUP BY
    CallId
  ORDER BY
    CallId
), CTE1 AS (
  SELECT DISTINCT
    f9.CallId,
    Timestamp,
    DATE_FORMAT(Timestamp, 'HH') AS hours,
    DATE_FORMAT(Timestamp, 'mm') AS minute,
    (
      hours * 100
    ) + minute,
    Agent,
    AgentName,
    CallType,
    Disposition,
    DispositionPath,
    CallTime,
    TalkTime,
    DNIS,
    ROW_NUMBER() OVER (PARTITION BY agent, CAST(timestamp AS DATE), dnis ORDER BY timestamp) AS UniqueCall,
    HandleTime,
    ConsultTime,
    TotalQueueTime,
    ManualTime,
    DialTime,
    AgentGroup,
    AfterCallWorkTime,
    HoldTime,
    RingTime,
    CASE
      WHEN CallType IN ('Inbound', 'Inbound Voicemail')
      THEN 'Inbound'
      WHEN Campaign IN ('AC IB Care Advisors', 'AC IB Customer Callback')
      THEN 'Inbound'
      ELSE 'Outbound'
    END AS Call_Direction,
    CASE
      WHEN Disposition IN (
        'AC Close Lead',
        'AC Confirm Activation',
        'AC Follow Up',
        'AC Prospect: Closed Lead',
        'AC Prospect: Confirmed SOC',
        'AC Qualified Re-Referred Home Care',
        'AC Qualified Transferred to SLA - Sr Living',
        'AC Reconnect Providers',
        'AC Survey-Did not Leave Voicemail',
        'AC Survey-Left Voicemail'
      )
      THEN 'Survey'
      WHEN Disposition = 'No Disposition'
      THEN 'No Disposition'
      ELSE 'Screening'
    END AS Business_Process,
    CASE
      WHEN Disposition IN ('AC Matched Hot Transferred', 'AC Matched Not Transferred')
      THEN CTE.Transfers_Attempted
      ELSE 0
    END AS TransfersAttempted
  FROM prod_homecare_acreporting_import.five9dailycalllogs AS f9
  LEFT JOIN CTE
    ON CTE.CallId = f9.CallId
  WHERE
    f9.Timestamp >= '2024-01-01'
)
SELECT DISTINCT
  *,
  CASE WHEN TransfersAttempted >= 1 THEN 'Yes' ELSE 'No' END AS Hot_Transfer_Attempted,
  CASE
    WHEN AgentName = 'Leeba Sara Exito'
    THEN 'sarae'
    WHEN AgentName = 'Gregory Alsola'
    THEN 'grega'
    ELSE LOWER(
      CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
    )
  END AS name_join
FROM CTE1
WHERE
  Timestamp >= '2025-01-01' AND AgentGroup = 'AC HCAM'
