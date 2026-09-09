-- Power BI query shape 462 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             114,894
-- Rows returned         3,088
-- Avg duration          777 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.opportunity, community_salesforce.opportunity_field_history, community_salesforce.user, prod_refined.gong_import_family_call, reporting.hcam_staffing
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CASE WHEN AgentName = 'Karen Isaak' THEN 'Karen isaak' ELSE AgentName END AS AgentName,
    Manager,
    `PowerBI Name`
  FROM main.reporting.hcam_staffing
  WHERE
    NOT Manager IS NULL
), CTEA AS (
  SELECT DISTINCT
    o.id,
    o.name AS OpportunityName,
    CAST(o.created_date AS DATE) AS CreatedDate,
    o.close_date,
    o.is_won,
    o.is_closed,
    o.stage_name AS CurrentStage,
    u.name AS HCAM,
    o.account_id,
    oh.old_value,
    oh.new_value
  FROM CTE
  JOIN main.community_salesforce.user AS u
    ON u.name = CTE.AgentName
  JOIN main.community_salesforce.opportunity AS o
    ON o.owner_id = u.id
  JOIN main.community_salesforce.opportunity_field_history AS oh
    ON oh.opportunity_id = o.id
  WHERE
    o.close_date >= '2026' AND oh.old_value = 'New' AND oh.new_value = 'Discovery'
), CTE1 AS (
  SELECT
    o.id,
    o.name AS OpportunityName,
    CAST(o.created_date AS DATE) AS CreatedDate,
    o.close_date,
    o.is_won,
    o.is_closed,
    CTE.Manager,
    CTE.`PowerBI Name`,
    o.stage_name AS CurrentStage,
    CTE.AgentName,
    o.account_id,
    CTEA.id AS New_to_Discovery
  FROM CTE
  JOIN main.community_salesforce.user AS u
    ON u.name = CTE.AgentName
  JOIN main.community_salesforce.opportunity AS o
    ON o.owner_id = u.id
  LEFT JOIN CTEA
    ON CTEA.id = o.id
  WHERE
    o.close_date >= '2026'
)
SELECT DISTINCT
  CTE1.AgentName,
  CASE WHEN g.gong_process_status = 'scheduled' THEN g.conversation_id ELSE NULL END AS MTDGongCalls,
  g.duration_seconds,
  CAST(call_start_at AS DATE)
FROM CTE1
LEFT JOIN main.prod_refined.gong_import_family_call AS g
  ON LOWER(CTE1.`PowerBI Name`) = LOWER(g.agent_username)
WHERE
  source_system = 'Zoom' AND CAST(call_start_at AS DATE) >= '2026'
