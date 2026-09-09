-- Power BI query shape 478 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             8,250
-- Rows returned         6,044
-- Avg duration          631 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.othercharge
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  oc.accountid,
  oc.createdon,
  CASE WHEN otherchargetypeid = 10 THEN -oc.amount ELSE oc.amount END AS amount,
  DATE_FORMAT(oc.createdon, 'MM-yyyy') AS Writeoff,
  oc.otherchargetypeid
FROM prod_homecare_actransactional_billing.othercharge AS oc
WHERE
  oc.otherchargetypeid IN (2, 10)
