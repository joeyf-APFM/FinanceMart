-- Power BI query shape 46 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,857
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             37,442,748,603
-- Rows returned         4,979,814,184
-- Avg duration          15,975 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 75a0183c-2c90-4d23-9c69-cdb19108448e, af940fd5-99cd-4e93-a620-822230b10ce8, da74b405-09e2-41e3-bed6-583fc3c4acae, eda315a6-a542-4102-b6ce-3551c75b1bdd
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
    f9.Timestamp >= '2024-06-01'
)
SELECT
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
  Timestamp >= DATE_ADD(MONTH, -5, CURRENT_DATE)
