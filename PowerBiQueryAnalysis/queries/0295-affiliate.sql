-- Power BI query shape 295 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            66
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             1,640,746,586
-- Rows returned         54,282,025
-- Avg duration          13,873 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectdisqualifier, prod_homecare_insite_directory.hmcprospectnotes, prod_homecare_insite_directory.hmcprospectphonenumber, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult, prod_homecare_insite_directory.hmcscreenqueue
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    r.HMCRequestID,
    r.affiliateid,
    CASE
      WHEN r.affiliateID IN (
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
      WHEN r.affiliateID = 87
      THEN 'SEO'
      WHEN r.affiliateID = 92
      THEN 'SEO'
      WHEN r.affiliateID IN (90, 107, 113)
      THEN 'Affiliates'
      WHEN r.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
      THEN 'APFM DQ'
      WHEN r.url LIKE '%msclkid%' OR r.url LIKE '%gclid%' OR r.url LIKE '%campaignid%'
      THEN 'SEM'
      WHEN r.url LIKE '%email%' OR r.affiliateID = 111
      THEN 'Email'
      WHEN r.affiliateID IN (6, 49) OR r.url LIKE '%/local%' OR r.url LIKE '%local/%'
      THEN 'SEO'
      WHEN r.affiliateID = 112
      THEN 'SEO'
      WHEN r.affiliateID = 72
      THEN 'APFM'
      WHEN r.url IS NULL AND r.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    p.createdate AS Prospect_Date,
    p.firstname,
    p.lastname,
    a.affiliatename,
    ppn.phonenumber,
    ROW_NUMBER() OVER (PARTITION BY r.HMCRequestID ORDER BY sr.createdate DESC) AS rn,
    p.Disqualifier,
    pd.Disqualifier AS Disqualifer_Text,
    REPLACE(REPLACE(REPLACE(p.DisqualifierReason, CHR(  10), ''), CHR(  13), ''), CHR(  9), '') AS DisqualiferReason,
    'https://admin.agingcare.com/HMCLeadQueue/Home/Prospect/',
    p.hmcprospectid AS Url,
    sr.userid,
    sr.createdate AS Screen_Date,
    REPLACE(REPLACE(REPLACE(pn.Note, CHR(  10), ''), CHR(  13), ''), CHR(  9), '') AS Note,
    sr.outcomeid AS ScreeningOutcome,
    p.postalcode
  FROM prod_homecare_insite_directory.hmcprospect AS p
  LEFT JOIN prod_homecare_insite_directory.hmcprospectdisqualifier AS pd
    ON pd.HMCProspectDisqualifierID = p.Disqualifier
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS r
    ON r.HMCProspectID = p.HMCProspectID
  LEFT JOIN prod_homecare_insite_directory.hmcscreenqueue AS sq
    ON r.HMCRequestID = sq.HMCRequestID
  LEFT JOIN prod_homecare_insite_directory.hmcscreeningresult AS sr
    ON r.hmcrequestid = sr.hmcrequestid
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hcl
    ON p.hmcprospectid = hcl.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectphonenumber AS ppn
    ON p.hmcprospectid = ppn.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.affiliate AS a
    ON r.affiliateid = a.affiliateid
  LEFT JOIN (
    SELECT
      HMCProspectID,
      CreateDate,
      Note,
      NoteID,
      Action,
      ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY CreateDate DESC) AS rn
    FROM prod_homecare_insite_directory.hmcprospectnotes
    WHERE
      Action NOT LIKE 'Disqualified'
      AND Action IN ('Answered Call', 'Responded to Email/Sms', 'Called In')
  ) AS pn
    ON pn.HMCProspectID = hcl.hmcprospectid
    AND CAST(pn.CreateDate AS DATE) = CAST(sr.createdate AS DATE)
    AND pn.rn = 1
  WHERE
    NOT p.Disqualifier IS NULL
    AND p.createdate >= '2024-01-01'
    AND r.requeststatusid <> 2
)
SELECT
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
    ELSE NULL
  END AS Source
FROM CTE
WHERE
  rn = 1 AND AdjChannel <> 'APFM' AND NOT AdjChannel IS NULL
