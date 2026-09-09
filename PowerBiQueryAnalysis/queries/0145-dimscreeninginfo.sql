-- Power BI query shape 145 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            378
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,992
-- Rows returned         3,024
-- Avg duration          610 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.dimscreeninginfo
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ScreeningInfoKey,
  ContactType,
  Qualified,
  Inbound
FROM prod_homecare_acreporting_reporting.dimscreeninginfo
