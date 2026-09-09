-- Power BI query shape 611 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             4,588,026
-- Rows returned         20,690
-- Avg duration          1,076 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  code,
  c.name AS City,
  sp.name AS State,
  dma.dma,
  p.name AS ProviderName
FROM main.prod_homecare_actransactional_geo.postalcode_01072025 AS pc
LEFT JOIN main.prod_homecare_actransactional_geo.city AS c
  ON c.cityid = pc.cityid
LEFT JOIN main.prod_homecare_actransactional_geo.stateprovince AS sp
  ON sp.stateprovinceid = pc.stateprovinceid
LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
  ON dma.zip = pc.code
LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.postalcodeid = pc.postalcodeid
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = psc.providerid
WHERE
  pc.countryid = 1
  AND dma.dma <> 'NA'
  AND psc.deleted = 0
  AND LOWER(p.name) LIKE 'home instead%'
