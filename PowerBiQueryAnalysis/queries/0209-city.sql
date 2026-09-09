-- Power BI query shape 209 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,079,909,109
-- Rows returned         142,943,496
-- Avg duration          9,983 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ci.Name,
    COUNT(DISTINCT (
      Code
    )) AS Zip_Count
  FROM prod_homecare_actransactional_geo.postalcode_01072025 AS pcv
  JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.PostalCodeID = pcv.PostalCodeID
  JOIN prod_homecare_actransactional_geo.city AS ci
    ON ci.CityID = pcv.CityID
  WHERE
    pcv.CountryID = 1 AND psc.deleted = 0
  GROUP BY
    ci.Name
  ORDER BY
    ci.Name
)
SELECT DISTINCT
  pro.name,
  psc.ProviderID,
  ci.Name AS City,
  sp.Name AS State,
  COUNT(Code) AS Zip_Count_Provider,
  Zip_Count AS Zip_Count_Total
FROM prod_homecare_actransactional_geo.postalcode_01072025 AS pcv
JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.PostalCodeID = pcv.PostalCodeID
JOIN prod_homecare_actransactional_geo.city AS ci
  ON ci.CityID = pcv.CityID
JOIN prod_homecare_actransactional_organization.provider AS pro
  ON pro.providerid = psc.providerid
JOIN prod_homecare_actransactional_geo.stateprovince AS sp
  ON sp.StateProvinceID = ci.StateProvinceID
JOIN CTE
  ON CTE.Name = ci.Name
WHERE
  pcv.CountryID = 1 AND psc.deleted = 0 AND ProviderStatusTypeID <> '3'
GROUP BY
  pro.name,
  psc.ProviderID,
  ci.Name,
  Zip_Count,
  sp.name
ORDER BY
  psc.ProviderID
