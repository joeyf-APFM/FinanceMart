-- Power BI query shape 297 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            62
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             225,900,099
-- Rows returned         225,900,099
-- Avg duration          4,860 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_dbo.users
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  u.userid,
  u.userkey,
  CASE WHEN u.usercode = 'tonyamarrillo' THEN 'tonya' ELSE u.usercode END AS usercode
FROM prod_homecare_insite_dbo.users AS u
