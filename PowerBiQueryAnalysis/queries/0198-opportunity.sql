-- Power BI query shape 198 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            250
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             12,213,386
-- Rows returned         13,775,317
-- Avg duration          1,135 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
-- Tables                community_salesforce.opportunity
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  id,
  owner_id,
  CAST(created_date AS DATE) AS CreatedDate,
  CAST(close_date AS DATE) AS CloseDate,
  stage_name
FROM main.community_salesforce.opportunity
WHERE
  created_date >= '2025'
