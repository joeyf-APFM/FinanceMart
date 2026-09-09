-- Power BI query shape 63 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,481
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             19,747,402,045
-- Rows returned         512,901,550
-- Avg duration          11,058 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_acreporting_dbo.zip_to_msa, prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_actransactional_geo.city, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcprospectid,
    hmcr.hmcrequestid,
    CASE WHEN hmcr.requeststatusid = 2 THEN hmcr.hmcrequestid ELSE NULL END AS Rl,
    CASE WHEN hmcr.requeststatusid <> 6 THEN hmcr.hmcrequestid ELSE NULL END AS LSTF,
    hmcr.createdate,
    hmcr.affiliateID,
    hmcr.url,
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
    r.Referralid,
    r.providerid,
    aff.affiliatename,
    r.BillingTypeID,
    hmcr.postalcode,
    r.returnapproved,
    msa.msa_name,
    ci.Name AS City,
    sp.name AS State,
    dca.source AS oSource
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.affiliate AS aff
    ON aff.affiliateid = hmcr.affiliateid
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN (
    SELECT
      *
    FROM prod_homecare_actransactional_homecare.referral
    WHERE
      NOT hmcleadid IS NULL
  ) AS r
    ON r.hmcleadid = hmcl.hmcleadid
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dchr
    ON hmcr.hmcrequestid = dchr.requestid
  LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
    ON dca.CustomerAcquisitionKey = dchr.CustomerAcquisitionKey
  LEFT JOIN prod_homecare_acreporting_dbo.zip_to_msa AS msa
    ON TRIM(msa.zip_code) = TRIM(hmcr.Postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_actransactional_geo.city AS ci
    ON ci.cityid = pc.cityid
  LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
    ON sp.stateprovinceid = pc.stateprovinceid
  WHERE
    hmcr.createdate >= DATE_ADD(DAY, -90, CAST(CURRENT_TIMESTAMP() AS DATE))
    AND hmcr.createdate < CAST(CURRENT_TIMESTAMP() AS DATE)
), CTE1 AS (
  SELECT DISTINCT
    *,
    CASE
      WHEN affiliateID = 87
      THEN 'Convertful'
      WHEN affiliateID = 92
      THEN 'Typeform'
      WHEN affiliateID = 90
      THEN 'Elderlife'
      WHEN affiliateID = 93
      THEN 'LNSTF'
      WHEN affiliateID = 94
      THEN 'SLA DQ'
      WHEN affiliateID = 95
      THEN 'LNSTF - CN'
      WHEN affiliateID = 96
      THEN 'LNSTF - WS'
      WHEN affiliateID = 97
      THEN 'LNSTF Inbound'
      WHEN affiliateID = 99
      THEN 'LNSTF - MaxZip'
      WHEN affiliateID = 106
      THEN 'SLADQ - WT'
      WHEN affiliateID = 108
      THEN 'No Tours'
      WHEN affiliateID = 112
      THEN 'APFM SEO'
      WHEN affiliateID = 113
      THEN 'Elderlife API'
      WHEN affiliateID = 117
      THEN 'Resistant to Referral'
      WHEN affiliateID = 119
      THEN 'SLA DQ LP'
      WHEN affiliateID = 121
      THEN 'HC Max Attempts'
      WHEN affiliateID = 133
      THEN 'Brand Verticles'
      WHEN AdjChannel = 'SEM' AND url LIKE '%msclkid%'
      THEN 'SEM - Bing'
      WHEN AdjChannel = 'SEM' AND url LIKE '%gclid%'
      THEN 'SEM - Google'
      WHEN AdjChannel = 'SEM' AND url LIKE '%campaignid%'
      THEN 'SEM - Unknown'
      WHEN AdjChannel = 'SEO' AND affiliateid = 6
      THEN 'AgingCare.com'
      WHEN AdjChannel = 'SEO' AND affiliateid = 49
      THEN 'Caregivers.com'
      WHEN AdjChannel = 'APFM'
      THEN 'APFM Screened Leads'
      WHEN AdjChannel = 'Email'
      THEN 'Email'
      ELSE affiliatename
    END AS Source,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      WHEN LOCATE('adgroup', url) = 0
      THEN NULL
      ELSE LEFT(url, LOCATE('adgroup', url) - 2)
    END AS Campaign1
  FROM CTE
  WHERE
    (
      billingtypeid = 3 OR billingtypeid IS NULL
    )
)
SELECT
  COUNT(DISTINCT hmcrequestid) AS Leads,
  COUNT(DISTINCT Rl) AS Rls,
  COUNT(DISTINCT LSTF) AS LSTFs,
  CAST(createdate AS DATE) AS CreateDate,
  COUNT(DISTINCT referralid) AS Referrals,
  postalcode,
  City,
  State,
  AdjChannel,
  CAST(returnapproved AS INT) AS returnapproved
FROM CTE1
GROUP BY
  postalcode,
  City,
  State,
  AdjChannel,
  CAST(createdate AS DATE),
  returnapproved
