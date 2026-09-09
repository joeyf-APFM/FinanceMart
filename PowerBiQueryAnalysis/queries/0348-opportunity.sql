-- Power BI query shape 348 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            17
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             84,214
-- Rows returned         36,222
-- Avg duration          423 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.opportunity, community_salesforce.opportunity_field_history, community_salesforce.user, reporting.hcam_staffing
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
)
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
