-- Power BI query shape 498 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             14,041
-- Rows returned         13,337
-- Avg duration          338 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.othercharge
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  oc.accountid,
  oc.createdon,
  oc.amount,
  DATE_FORMAT(oc.createdon, 'MM-yyyy') AS Promos,
  oc.otherchargetypeid,
  statementid
FROM prod_homecare_actransactional_billing.othercharge AS oc
WHERE
  oc.otherchargetypeid = 1
