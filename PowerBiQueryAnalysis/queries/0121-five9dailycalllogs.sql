-- Power BI query shape 121 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            490
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             9,734,140,605
-- Rows returned         2,350,289,226
-- Avg duration          29,322 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
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
  WHERE
    agentgroup = 'AC Care Advisors'
  GROUP BY
    CallId
  ORDER BY
    CallId
), CTE1 AS (
  SELECT DISTINCT
    f9.CallId,
    Timestamp,
    Agent,
    AgentName,
    CallType,
    Disposition,
    DispositionPath,
    CallTime,
    TalkTime,
    DNIS,
    HandleTime,
    ConsultTime,
    TotalQueueTime,
    ManualTime,
    DialTime,
    AfterCallWorkTime,
    HoldTime,
    RingTime,
    CASE
      WHEN CallType IN ('Inbound')
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
    f9.Timestamp >= '2025' AND f9.agentgroup = 'AC Care Advisors'
)
SELECT
  DATE_FORMAT(timestamp, 'HHmm') AS Time,
  *,
  CASE WHEN TransfersAttempted >= 1 THEN 'Yes' ELSE 'No' END AS Hot_Transfer_Attempted,
  CASE
    WHEN AgentName = 'Leeba Sara Exito'
    THEN 'sarae'
    WHEN AgentName = 'Gregory Alsola'
    THEN 'grega'
    WHEN AgentName = 'Kate Cruz'
    THEN 'kate.cruz'
    WHEN AgentName = 'Rose Emilia'
    THEN 'roseem'
    ELSE LOWER(
      CONCAT(LEFT(Agent, LOCATE('.', Agent) - 1), SUBSTRING(Agent, LOCATE('.', Agent) + 1, 1))
    )
  END AS name_join
FROM CTE1
WHERE
  Timestamp >= '2025-06-01'
