-- Power BI query shape 536 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             81,254
-- Rows returned         416
-- Avg duration          344 ms
-- Power BI datasets     none recorded
-- Tables                reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  DMA,
  CASE
    WHEN dma IN ('Atlanta', 'Houston', 'Boston')
    THEN 'Grace DMA'
    ELSE 'Non Grace DMA'
  END AS GraceDMA
FROM main.reporting.dim_geography_zip_dma
WHERE
  dma <> 'NA'
