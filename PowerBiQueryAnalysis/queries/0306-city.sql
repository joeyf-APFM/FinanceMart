-- Power BI query shape 306 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            56
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,451,580
-- Rows returned         2,084,320
-- Avg duration          766 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.city
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CityID,
  Name,
  StateProvinceID,
  ModifiedOn,
  ModifiedBy,
  CreatedOn,
  CreatedBy
FROM prod_homecare_actransactional_geo.city
