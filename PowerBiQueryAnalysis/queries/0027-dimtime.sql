-- Power BI query shape 27 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,422
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             486,720
-- Rows returned         3,487,680
-- Avg duration          341 ms
-- Power BI datasets     2cceff05-ca68-44c0-8f76-545dd698db36
-- Tables                prod_homecare_acreporting_reporting.dimtime
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  *,
  CASE WHEN timeid >= 800 AND timeid < 2100 THEN 'Yes' ELSE 'No' END AS In_Business_Hours
FROM prod_homecare_acreporting_reporting.dimtime
