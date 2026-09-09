-- Power BI query shape 437 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             89,158
-- Rows returned         83,254
-- Avg duration          439 ms
-- Power BI datasets     none recorded
-- Tables                reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  DMA,
  zip,
  CASE
    WHEN dma IN (
      'Atlanta',
      'Houston',
      'Boston',
      'Chicago',
      'Dallas',
      'Los Angeles',
      'Philadelphia',
      'Sacramento',
      'San Francisco',
      'Tampa',
      'Washington DC'
    )
    THEN 'Grace DMA'
    ELSE 'Non Grace DMA'
  END AS GraceDMA
FROM main.reporting.dim_geography_zip_dma
WHERE
  dma <> 'NA'
