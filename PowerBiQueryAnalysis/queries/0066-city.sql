-- Power BI query shape 66 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,473
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             13,087,035
-- Rows returned         54,825,060
-- Avg duration          573 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.stateprovince
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CityID,
  c.Name AS City,
  CONCAT(c.Name, ', ', st.Iso2Code) AS City_State,
  c.StateProvinceID,
  c.ModifiedOn,
  c.ModifiedBy,
  c.CreatedOn,
  c.CreatedBy
FROM prod_homecare_actransactional_geo.city AS c
LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS st
  ON c.StateProvinceID = st.StateProvinceID
