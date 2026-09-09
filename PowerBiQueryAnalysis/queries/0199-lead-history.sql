-- Power BI query shape 199 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            250
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             106,122,672
-- Rows returned         120,727,551
-- Avg duration          8,155 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
-- Tables                community_salesforce.lead_history
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  id,
  CAST(created_date AS DATE) AS CreatedDate,
  is_deleted,
  lead_id,
  new_value,
  old_value,
  field
FROM main.community_salesforce.lead_history
WHERE
  created_date >= '2025'
  AND field = 'Owner'
  AND new_value NOT LIKE '00%'
  AND new_value NOT LIKE 'APFMA%'
