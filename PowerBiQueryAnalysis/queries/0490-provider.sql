-- Power BI query shape 490 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             13,195,061
-- Rows returned         72,061
-- Avg duration          5,757 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    CASE WHEN DMA IS NULL THEN 'NA' ELSE DMA END AS DMA_Name,
    CASE
      WHEN DMA IN (
        'Yuma',
        'Youngstown',
        'Glendive',
        'Alpena',
        'Fairbanks',
        'Victoria',
        'Casper',
        'Great Falls',
        'Ottumwa',
        'Parkersburg',
        'Mankato',
        'Butte-Bozeman',
        'Cheyenne',
        'Grand Junction',
        'Lima',
        'Eureka',
        'Watertown',
        'Lake Charles',
        'Hattiesburg',
        'Bend',
        'Elmira',
        'Columbus',
        'Clarksburg',
        'Rochester MN',
        'Idaho',
        'Joplin',
        'Jackson TN',
        'Utica',
        'Abilene',
        'Wichita Falls',
        'Dothan',
        'Missoula',
        'Albany GA',
        'Rockford',
        'Erie',
        'Odessa',
        'Anchorage',
        'Fargo',
        'Topeka',
        'Binghamton',
        'MO',
        'Lincoln',
        'Chico',
        'Gainesville',
        'Eugene',
        'Corpus Christi',
        'Panama City',
        'Jackson MS',
        'Columbus GA',
        'Cedar Rapids',
        'Monterey',
        'Bakersfield',
        'Tallahassee',
        'Fort Wayne',
        'Shreveport',
        'Tri-Cities TN',
        'Wilmington',
        'Green Bay',
        'Wichita',
        'Madison',
        'Chattanooga',
        'Charleston',
        'Augusta',
        'Colorado',
        'Tyler',
        'Burlington',
        'Santa Barbara',
        'Fort Smith',
        'Springfield MO',
        'South Bend',
        'El Paso',
        'Des Moines',
        'Waco',
        'Roanoke',
        'Honolulu',
        'Myrtle',
        'New Orleans',
        'Fresno',
        'Albany',
        'Dayton',
        'Mobile',
        'Tucson',
        'Louisville',
        'Little Rock',
        'Columbus OH',
        'Salt Lake City',
        'Albuquerque',
        'Seattle',
        'Nashville',
        'San Antonio',
        'Jacksonville',
        'Portland',
        'Charlotte',
        'West Palm Beach',
        'St. Louis',
        'Greenville',
        'Baltimore',
        'Sacramento',
        'Phoenix',
        'Ft. Meyers',
        'Orlando',
        'Dallas',
        'Chicago',
        'Atlanta',
        'Los Angeles'
      )
      THEN 'Test Group'
      ELSE 'Control Group'
    END AS Group,
    psc.providerid,
    TotalPostalCodes,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    COUNT(DISTINCT psc.postalcode) AS PostalCodes
  FROM prod_homecare_actransactional_organization.providerservicecoverage AS psc
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON psc.providerid = p.providerid
  LEFT JOIN reporting.dim_geography_zip_dma AS dma
    ON psc.postalcode = dma.zip
  LEFT JOIN (
    SELECT
      providerid,
      COUNT(DISTINCT postalcode) AS TotalPostalCodes
    FROM prod_homecare_actransactional_organization.providerservicecoverage AS psc
    WHERE
      deleted = 0
    GROUP BY
      providerid
  ) AS total
    ON total.providerid = psc.providerid
  WHERE
    psc.deleted = 0 AND billingtypeid = 3
  GROUP BY
    1,
    2,
    3,
    4,
    5
  ORDER BY
    providerid
)
SELECT
  DMA_Name,
  Group,
  ProviderID,
  TotalPostalCodes,
  PostalCodes,
  PostalCodes / TotalPostalCodes,
  Org,
  CASE
    WHEN PostalCodes / TotalPostalCodes = 1
    THEN 'Single DMA'
    ELSE 'Multiple DMA'
  END AS DMA_Grouping
FROM CTE
