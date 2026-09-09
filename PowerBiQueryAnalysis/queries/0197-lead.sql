-- Power BI query shape 197 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            250
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             11,579,050
-- Rows returned         13,168,955
-- Avg duration          1,207 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
-- Tables                community_salesforce.lead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  l.id,
  CAST(l.created_date AS DATE) AS CreatedDate,
  l.converted_opportunity_id,
  l.owner_id
FROM main.community_salesforce.lead AS l
WHERE
  l.created_date >= '2025'
