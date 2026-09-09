-- Power BI query shape 584 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             352,295
-- Rows returned         349,199
-- Avg duration          1,264 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.opportunity_field_history
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  Id,
  Opportunity_Id,
  Field,
  Old_Value,
  New_Value,
  created_date AS CreatedDate
FROM main.community_salesforce.opportunity_field_history
WHERE
  created_date >= '2024-10-15'
