-- Power BI query shape 196 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            251
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             139,993
-- Rows returned         190,342
-- Avg duration          963 ms
-- Power BI datasets     146cde38-6c07-42a1-97e7-30a21a563d0d
-- Tables                community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  id,
  username,
  Name
FROM main.community_salesforce.user
