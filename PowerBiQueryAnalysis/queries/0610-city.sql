-- Power BI query shape 610 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             201,382
-- Rows returned         41,617
-- Avg duration          1,631 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  code,
  c.name AS City,
  sp.name AS State,
  dma.dma
FROM main.prod_homecare_actransactional_geo.postalcode_01072025 AS pc
LEFT JOIN main.prod_homecare_actransactional_geo.city AS c
  ON c.cityid = pc.cityid
LEFT JOIN main.prod_homecare_actransactional_geo.stateprovince AS sp
  ON sp.stateprovinceid = pc.stateprovinceid
LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
  ON dma.zip = pc.code
WHERE
  pc.countryid = 1 AND dma.dma <> 'NA'
