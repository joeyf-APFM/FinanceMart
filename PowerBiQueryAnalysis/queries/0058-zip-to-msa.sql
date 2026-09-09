-- Power BI query shape 58 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,483
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,432,371,141
-- Rows returned         62,479,945
-- Avg duration          38,242 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_acreporting_dbo.zip_to_msa, prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    hmcr.requeststatusid,
    TRIM(hmcr.postalcode) AS postalcode,
    msa_name,
    CAST(hmcr.createdate AS DATE) AS createdate,
    CASE
      WHEN hmcr.affiliateid = 72
      THEN 'APFM'
      WHEN hmcr.affiliateID IN (
        98,
        100,
        101,
        102,
        103,
        104,
        105,
        109,
        110,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132
      )
      THEN 'SEM'
      WHEN hmcr.affiliateID = 87
      THEN 'SEO'
      WHEN hmcr.affiliateID = 92
      THEN 'SEO'
      WHEN hmcr.affiliateID IN (90, 107, 113, 133)
      THEN 'Affiliates'
      WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 136, 121, 136)
      THEN 'APFM DQ'
      WHEN hmcr.url LIKE '%msclkid%'
      OR hmcr.url LIKE '%gclid%'
      OR hmcr.url LIKE '%campaignid%'
      THEN 'SEM'
      WHEN hmcr.url LIKE '%email%' OR hmcr.affiliateID = 111
      THEN 'Email'
      WHEN hmcr.affiliateid IN (6, 49)
      OR hmcr.url LIKE '%/local%'
      OR hmcr.url LIKE '%local/%'
      THEN 'SEO'
      WHEN hmcr.affiliateID = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    CASE WHEN NOT temp.postalcode IS NULL THEN hmcr.hmcrequestid ELSE NULL END AS MontlyCapped
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_acreporting_dbo.zip_to_msa AS msa
    ON TRIM(msa.zip_code) = TRIM(hmcr.Postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
    ON sp.stateprovinceid = pc.stateprovinceid
  LEFT JOIN prod_homecare_actransactional_geo.city AS ci
    ON ci.cityid = pc.cityid
  LEFT JOIN (
    SELECT DISTINCT
      date,
      cte.providerid,
      providername,
      psc.postalcode,
      orderid,
      orderstatusreason
    FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cte
    LEFT JOIN prod_homecare_actransactional_organization.provider AS p
      ON p.providerid = cte.providerid
    LEFT JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
      ON cte.providerid = psc.providerid
    WHERE
      orderstatusreason = 'Monthly Cap Reached' AND p.deleted = 0 AND psc.deleted = 0
  ) AS temp
    ON TRIM(temp.postalcode) = TRIM(hmcr.postalcode)
    AND CAST(temp.date AS DATE) = CAST(hmcr.createdate AS DATE)
  WHERE
    hmcr.requeststatusid = 6
    AND hmcr.createdate >= DATE_ADD(DAY, -90, CAST(CURRENT_TIMESTAMP() AS DATE))
    AND hmcr.createdate < CAST(CURRENT_TIMESTAMP() AS DATE)
)
SELECT
  createdate,
  postalcode,
  AdjChannel,
  COUNT(DISTINCT hmcrequestid) AS All_LNSTF,
  COUNT(DISTINCT MontlyCapped) AS LNSTF_MonthlyCap,
  COUNT(DISTINCT hmcrequestid) - COUNT(DISTINCT MontlyCapped) AS LNSTF_No_Providers
FROM CTE
WHERE
  postalcode <> 99732
GROUP BY
  createdate,
  postalcode,
  AdjChannel
ORDER BY
  createdate DESC,
  postalcode
