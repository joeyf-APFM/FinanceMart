-- Power BI query shape 215 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             153,707,456
-- Rows returned         218,917,998
-- Avg duration          4,147 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, 36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  pcv.code,
  ci.name AS City,
  sp.name AS State,
  CONCAT(ci.name, ', ', sp.name) AS Location,
  ROUND(AVG(Latitude), 2) AS Latitude,
  ROUND(AVG(Longitude), 2) AS Longitude
FROM prod_homecare_actransactional_geo.postalcode_01072025 AS pcv
JOIN prod_homecare_actransactional_geo.city AS ci
  ON ci.CityID = pcv.CityID
JOIN prod_homecare_actransactional_geo.stateprovince AS sp
  ON sp.StateProvinceID = ci.StateProvinceID
GROUP BY
  pcv.code,
  ci.name,
  sp.name,
  ci.name + ', ' + sp.name
