-- Power BI query shape 367 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            9
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,816,970
-- Rows returned         17,728
-- Avg duration          223 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.task, community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  COUNT(DISTINCT t.id) AS Tasks,
  u.name,
  CAST(t.created_date AS DATE) AS CreateDate
FROM main.community_salesforce.task AS t
JOIN main.community_salesforce.user AS u
  ON u.id = t.owner_id
WHERE
  t.created_date >= '2026'
GROUP BY
  2,
  3
