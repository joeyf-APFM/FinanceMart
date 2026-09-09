-- Power BI query shape 303 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,740,320
-- Rows returned         2,610,480
-- Avg duration          340 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_dbo.zip_to_msa
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ZIP_CODE,
  STATE,
  MSA_No,
  County_No,
  MSA_Name
FROM prod_homecare_acreporting_dbo.zip_to_msa
