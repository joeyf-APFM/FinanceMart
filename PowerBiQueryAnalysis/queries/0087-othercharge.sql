-- Power BI query shape 87 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            989
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             801,540
-- Rows returned         3,141,610
-- Avg duration          324 ms
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
  oc.otherchargetypeid
FROM prod_homecare_actransactional_billing.othercharge AS oc
WHERE
  oc.otherchargetypeid = 2
