-- Power BI query shape 65 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,474
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,159,378
-- Rows returned         4,800,818
-- Avg duration          453 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_geo.county, prod_homecare_actransactional_geo.stateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CountyID,
  county.Name AS County_Name,
  CONCAT(county.Name, ' County, ', st.Iso2Code) AS County_State,
  county.StateProvinceID,
  county.CreatedOn,
  county.CreatedBy,
  county.ModifiedOn,
  county.ModifiedBy
FROM prod_homecare_actransactional_geo.county AS county
LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS st
  ON county.StateProvinceID = st.StateProvinceID
WHERE
  CountyID <> -1
