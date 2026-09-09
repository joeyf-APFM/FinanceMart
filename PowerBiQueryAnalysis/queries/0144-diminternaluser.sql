-- Power BI query shape 144 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            379
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             145,542
-- Rows returned         217,167
-- Avg duration          652 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.diminternaluser, prod_homecare_acreporting_reporting.facthomecarescreeningtransaction
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  InternalUserKey,
  InternalUserID,
  LegacyUserID,
  CASE WHEN InternalUserKey = 369 THEN 'sarae' ELSE LOWER(FirstName) END AS FirstName,
  LastName
FROM prod_homecare_acreporting_reporting.diminternaluser AS diu
LEFT JOIN prod_homecare_acreporting_reporting.facthomecarescreeningtransaction AS hcst
  ON diu.InternalUserKey = hcst.CareAdivsorInternalUserKey
ORDER BY
  FirstName DESC
