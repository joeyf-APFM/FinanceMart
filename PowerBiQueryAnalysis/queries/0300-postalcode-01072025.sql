-- Power BI query shape 300 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,693,614
-- Rows returned         2,605,560
-- Avg duration          735 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.postalcode_01072025
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  PostalCodeID,
  Code,
  CountryID,
  StateProvinceID,
  CountyID,
  CityID,
  Latitude,
  Longitude,
  ModifiedOn,
  ModifiedBy,
  CreatedOn,
  CreatedBy
FROM prod_homecare_actransactional_geo.postalcode_01072025
WHERE
  CountryID = 1
