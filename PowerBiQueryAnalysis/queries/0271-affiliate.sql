-- Power BI query shape 271 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            103
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             118,262,517
-- Rows returned         117,811,437
-- Avg duration          10,316 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmcprospectnotes, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcrequestid,
    hmcr.affiliateid,
    a.affiliatename,
    url,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
    src.HMCProspectID AS SRCProspect,
    CASE
      WHEN NOT src.HMCProspectID IS NULL
      THEN 'APFM DQ'
      WHEN hmcr.affiliateid IN (140, 141)
      THEN 'Grace'
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
        132,
        134
      )
      THEN 'SEM'
      WHEN hmcr.affiliateID = 87
      THEN 'SEO'
      WHEN hmcr.affiliateID = 92
      THEN 'SEO'
      WHEN hmcr.affiliateID IN (90, 107, 113, 133)
      THEN 'Affiliates'
      WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121, 136)
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
      WHEN hmcr.affiliateid = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid = 138
      THEN 'AgingCare Manual'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN prod_homecare_insite_directory.affiliate AS a
    ON a.affiliateID = hmcr.affiliateid
  LEFT JOIN (
    SELECT
      HMCProspectID,
      CreateDate,
      Note,
      NoteID,
      Action,
      ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY CreateDate DESC) AS rns
    FROM prod_homecare_insite_directory.hmcprospectnotes
    WHERE
      Action NOT LIKE 'Disqualified'
      AND Action IN ('Answered Call', 'Responded to Email/Sms', 'Called In')
      AND LEFT(Note, 3) = 'SRC'
  ) AS src
    ON src.HMCProspectID = hmcr.hmcprospectid AND hmcr.createdate <= src.createdate
  WHERE
    hmcr.createdate >= DATE_ADD(MONTH, -8, CURRENT_TIMESTAMP())
)
SELECT DISTINCT
  hmcrequestid,
  affiliateid,
  AdjChannel,
  CASE
    WHEN NOT SRCProspect IS NULL
    THEN 'LNSTF - CN'
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
  END AS Source
FROM CTE
