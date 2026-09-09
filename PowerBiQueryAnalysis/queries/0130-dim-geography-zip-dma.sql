-- Power BI query shape 130 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            430
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             20,228,249
-- Rows returned         17,627,323
-- Avg duration          1,029 ms
-- Power BI datasets     fe02549c-24f9-4a63-88e9-89efbaf400ed
-- Tables                reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    zip,
    dma
  FROM reporting.dim_geography_zip_dma
  WHERE
    dma <> 'NA'
)
SELECT DISTINCT
  CASE WHEN CTE.DMA IS NULL THEN dma.DMA ELSE CTE.DMA END AS DMA,
  CASE WHEN CTE.zip IS NULL THEN dma.zip ELSE CTE.zip END AS Zip
FROM reporting.dim_geography_zip_dma AS dma
LEFT JOIN CTE
  ON CTE.zip = dma.zip
