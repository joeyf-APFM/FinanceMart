-- Power BI query shape 325 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,068,534
-- Rows returned         356,178
-- Avg duration          4,125 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_import.five9dailycalllogs
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CallLogId,
  CallId,
  Timestamp,
  Agent,
  AgentName,
  AgentGroup,
  Skill,
  Campaign,
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
  RingTime
FROM prod_homecare_acreporting_import.five9dailycalllogs
WHERE
  Campaign IN ('AC OB Deactivated Leads', 'AC IB Deactivated Leads Callback')
  AND DNIS <> 0
ORDER BY
  DNIS
