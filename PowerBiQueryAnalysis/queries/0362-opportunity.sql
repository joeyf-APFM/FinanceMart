-- Power BI query shape 362 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            10
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             67,496
-- Rows returned         73,803
-- Avg duration          249 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.opportunity
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  o.ID,
  o.Name,
  o.Owner_ID AS OwnerId,
  CAST(o.close_date AS DATE) AS CloseDate,
  CAST(o.created_date AS DATE) AS CreatedDate,
  is_won AS IsWon,
  is_closed AS IsClosed,
  DATE_FORMAT(o.close_date, 'yyyyMM') AS ClosedDateID
FROM main.community_salesforce.opportunity AS o
WHERE
  o.created_date >= '2025'
