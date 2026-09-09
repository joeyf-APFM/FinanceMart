-- Power BI query shape 583 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,283,546
-- Rows returned         204,473
-- Avg duration          537 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.hmcrequest, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hmcr.hmcrequestid,
  DMA
FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
  ON dma.zip = TRIM(hmcr.postalcode)
WHERE
  hmcr.createdate >= '2024' AND dma IN ('Boston', 'Houston', 'Atlanta')
