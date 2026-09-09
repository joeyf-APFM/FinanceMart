-- Power BI query shape 7 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3,233
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,001,471,719
-- Rows returned         1,033,962,299
-- Avg duration          2,068 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hrt.referralid,
  hrt.hottransferresponseid,
  hr.name
FROM prod_homecare_actransactional_homecare.hottransferresult AS hrt
LEFT JOIN prod_homecare_actransactional_homecare.hottransferresponse AS hr
  ON hr.hottransferresponseid = hrt.hottransferresponseid
