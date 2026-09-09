-- Power BI query shape 42 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,066
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             37,787,022,825
-- Rows returned         2,462,724,496
-- Avg duration          9,862 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectdisqualifier, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcpd.disqualifier AS Disqualifier2,
    hmcp.disqualifierreason,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
    CASE
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
      WHEN hmcr.affiliateID IN (90, 107, 113)
      THEN 'Affiliates'
      WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
      THEN 'APFM DQ'
      WHEN hmcr.url LIKE '%msclkid%'
      OR hmcr.url LIKE '%gclid%'
      OR hmcr.url LIKE '%campaignid%'
      THEN 'SEM'
      WHEN hmcr.url LIKE '%email%' OR affiliateID = 111
      THEN 'Email'
      WHEN hmcr.affiliateid IN (6, 49)
      OR hmcr.url LIKE '%/local%'
      OR hmcr.url LIKE '%local/%'
      THEN 'SEO'
      WHEN hmcr.affiliateID = 112
      THEN 'SEO'
      WHEN hmcr.affiliateid = 72
      THEN 'APFM'
      WHEN hmcr.url IS NULL AND affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    hmcr.affiliateID,
    hmcr.url,
    hmcr.createdate AS RequestDateTime,
    hmcr.RequestStatusID,
    1 AS Lead,
    CASE WHEN hmcr.RequestStatusID = 6 THEN 0 ELSE 1 END AS LSTF,
    CASE WHEN hmcr.RequestStatusID = 2 THEN 1 ELSE 0 END AS RL
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectdisqualifier AS hmcpd
    ON hmcpd.hmcprospectdisqualifierid = hmcp.disqualifier
), CTE2 AS (
  SELECT
    HMCRequestID,
    HMCProspectID,
    affiliateID,
    Flow,
    Disqualifier2,
    disqualifierreason,
    AdjChannel AS Channel,
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
      ELSE 'null'
    END AS Source,
    CASE
      WHEN AdjChannel <> 'SEO'
      THEN NULL
      WHEN affiliateID = 87
      THEN 'Convertful'
      WHEN affiliateID = 92
      THEN 'Typeful'
      WHEN affiliateID = 'Caregivers.com'
      THEN NULL
      WHEN url LIKE '%/local/in-home-care%'
      THEN 'In Home Care Page'
      WHEN url = '/local'
      THEN '/local Page'
      WHEN url LIKE '%/local/search%'
      THEN 'Search'
      WHEN url LIKE '%lp/homecare%'
      THEN 'SEM LP'
      WHEN url LIKE '%local/%' AND LENGTH(url) > 10
      THEN 'Provider Pages'
      ELSE 'Unknown'
    END AS SiteSection,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      WHEN affiliateID = 98
      THEN 'ParentsSEMForm'
      WHEN affiliateID = 100
      THEN 'Alzheimers SEM Form'
      WHEN affiliateID = 101
      THEN 'Hourly SEM Form'
      WHEN affiliateID = 102
      THEN 'Immeditate SEM Form'
      WHEN affiliateID = 103
      THEN 'PostOp SEM Lead Form'
      WHEN affiliateID = 104
      THEN 'Spouses SEM Lead Form'
      WHEN affiliateID = 105
      THEN 'Short Quiz SEM Form'
      WHEN affiliateID = 109
      THEN 'AC Google SEM Inbound'
      WHEN affiliateID = 110
      THEN 'Better Path SEM'
      WHEN affiliateID = 123
      THEN 'Better Path SEM Quickfill'
      WHEN affiliateID = 124
      THEN 'Better Path SEM Parents'
      WHEN affiliateID = 125
      THEN 'Better Path SEM Hourly'
      WHEN affiliateID = 126
      THEN 'Better Path SEM Immediate'
      WHEN affiliateID = 127
      THEN 'Better Path SEM Hospice'
      WHEN affiliateID = 128
      THEN 'Better Path SEM Memory Care'
      WHEN affiliateID = 129
      THEN 'Better Path SEM Respite'
      WHEN affiliateID = 130
      THEN 'Better Path Visual Buttons'
      WHEN affiliateID = 131
      THEN 'Costs and Services SEM Form'
      WHEN affiliateID = 132
      THEN 'Better Path SEM Care Finder'
    END AS SEMForm,
    url,
    RequestDateTime,
    RequestStatusID,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      WHEN LOCATE('adgroup', url) = 0
      THEN NULL
      ELSE LEFT(url, LOCATE('adgroup', url) - 2)
    END AS Campaign1,
    Lead,
    LSTF,
    RL
  FROM CTE
), CTE3 AS (
  SELECT
    HMCRequestID,
    HMCProspectID AS HMCProspectID2,
    Disqualifier2,
    disqualifierreason,
    Flow,
    affiliateID AS affiliateID2,
    Channel,
    Source
  FROM CTE2
  WHERE
    affiliateID IN (117)
), CTEA AS (
  SELECT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcpd.disqualifier,
    HMCProspectID2,
    affiliateID2,
    disqualifier2,
    hmcr.requeststatusid,
    hmcp.disqualifierreason,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
    CASE
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
      WHEN hmcr.affiliateID IN (90, 107, 113)
      THEN 'Affiliates'
      WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
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
      WHEN hmcr.affiliateid = 72
      THEN 'APFM'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    CASE
      WHEN tz.timezoneid = 4
      THEN CONVERT_TIMEZONE('America/Detroit', 'Pacific/Honolulu', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 6
      THEN CONVERT_TIMEZONE('America/Detroit', 'US/Alaska', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 10
      THEN CONVERT_TIMEZONE('America/Detroit', 'US/Pacific', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 13
      THEN CONVERT_TIMEZONE('America/Detroit', 'America/Boise', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 15
      THEN CONVERT_TIMEZONE('America/Detroit', 'America/Chicago', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 26
      THEN CONVERT_TIMEZONE('America/Detroit', 'America/Glace_Bay', CAST(hmcr.createdate AS TIMESTAMP))
      WHEN tz.timezoneid = 20
      THEN CONVERT_TIMEZONE('America/Detroit', 'America/Detroit', CAST(hmcr.createdate AS TIMESTAMP))
      ELSE hmcr.createdate
    END AS Adjust_CreateDate,
    hmcr.affiliateID,
    hmcr.url,
    hmcr.createdate AS RequestDateTime,
    hmcr.RequestStatusID,
    1 AS Lead,
    CASE WHEN hmcr.RequestStatusID = 6 THEN 0 ELSE 1 END AS LSTF,
    CASE WHEN hmcr.RequestStatusID = 2 THEN 1 ELSE 0 END AS RL
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectdisqualifier AS hmcpd
    ON hmcpd.hmcprospectdisqualifierid = hmcp.disqualifier
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
    ON tz.timezoneid = pc.timezoneid
  LEFT JOIN CTE3
    ON CTE3.hmcprospectid2 = hmcr.hmcprospectid
  WHERE
    hmcr.createdate >= '2024-01-01'
), CTEB AS (
  SELECT
    HMCRequestID,
    HMCProspectID,
    HMCProspectID2,
    affiliateID,
    affiliateID2,
    requeststatusid,
    Flow,
    disqualifier,
    DATE_FORMAT(Adjust_CreateDate, 'HH') AS hours,
    DATE_FORMAT(Adjust_CreateDate, 'mm') AS minute,
    (
      hours * 100
    ) + minute AS TimeID,
    disqualifier2,
    disqualifierreason,
    Adjust_CreateDate,
    AdjChannel AS Channel,
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
      ELSE 'null'
    END AS Source,
    CASE
      WHEN AdjChannel <> 'SEO'
      THEN NULL
      WHEN affiliateID = 87
      THEN 'Convertful'
      WHEN affiliateID = 92
      THEN 'Typeful'
      WHEN affiliateID = 'Caregivers.com'
      THEN NULL
      WHEN url LIKE '%/local/in-home-care%'
      THEN 'In Home Care Page'
      WHEN url = '/local'
      THEN '/local Page'
      WHEN url LIKE '%/local/search%'
      THEN 'Search'
      WHEN url LIKE '%lp/homecare%'
      THEN 'SEM LP'
      WHEN url LIKE '%local/%' AND LENGTH(url) > 10
      THEN 'Provider Pages'
      ELSE 'Unknown'
    END AS SiteSection,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      WHEN affiliateID = 98
      THEN 'ParentsSEMForm'
      WHEN affiliateID = 100
      THEN 'Alzheimers SEM Form'
      WHEN affiliateID = 101
      THEN 'Hourly SEM Form'
      WHEN affiliateID = 102
      THEN 'Immeditate SEM Form'
      WHEN affiliateID = 103
      THEN 'PostOp SEM Lead Form'
      WHEN affiliateID = 104
      THEN 'Spouses SEM Lead Form'
      WHEN affiliateID = 105
      THEN 'Short Quiz SEM Form'
      WHEN affiliateID = 109
      THEN 'AC Google SEM Inbound'
      WHEN affiliateID = 110
      THEN 'Better Path SEM'
      WHEN affiliateID = 123
      THEN 'Better Path SEM Quickfill'
      WHEN affiliateID = 124
      THEN 'Better Path SEM Parents'
      WHEN affiliateID = 125
      THEN 'Better Path SEM Hourly'
      WHEN affiliateID = 126
      THEN 'Better Path SEM Immediate'
      WHEN affiliateID = 127
      THEN 'Better Path SEM Hospice'
      WHEN affiliateID = 128
      THEN 'Better Path SEM Memory Care'
      WHEN affiliateID = 129
      THEN 'Better Path SEM Respite'
      WHEN affiliateID = 130
      THEN 'Better Path Visual Buttons'
      WHEN affiliateID = 131
      THEN 'Costs and Services SEM Form'
      WHEN affiliateID = 132
      THEN 'Better Path SEM Care Finder'
    END AS SEMForm,
    url,
    RequestDateTime,
    RequestStatusID,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      WHEN LOCATE('adgroup', url) = 0
      THEN NULL
      ELSE LEFT(url, LOCATE('adgroup', url) - 2)
    END AS Campaign1,
    Lead,
    LSTF,
    RL,
    TimeID
  FROM CTEA
)
SELECT DISTINCT
  CTEB.HMCRequestID,
  CTEB.HMCProspectID,
  disqualifier,
  userid,
  DATE_FORMAT(Adjust_CreateDate, 'HH:mm') AS Time,
  CASE
    WHEN requeststatusid = 4
    THEN 'Max Attempts'
    WHEN CTEB.HMCProspectID = HMCProspectID2 AND affiliateid2 IN (117)
    THEN 'Resistant to Referral'
    WHEN CTEB.HMCProspectID IS NULL AND requeststatusid = 3
    THEN 'Misdirected Request'
    WHEN disqualifier IS NULL AND requeststatusid = 5
    THEN 'Hard Stop'
    WHEN disqualifier IS NULL AND requeststatusid = 7
    THEN 'APFM Matches Ignored'
    WHEN disqualifier IS NULL AND requeststatusid = 8
    THEN 'Duplicated'
    ELSE disqualifier
  END AS disqualifierfixed,
  CASE
    WHEN CTEB.HMCProspectID = HMCProspectID2 AND affiliateid2 IN (117)
    THEN NULL
    ELSE disqualifierreason
  END AS disqualifierreason_fixed,
  disqualifierreason,
  Flow,
  affiliateID,
  Channel,
  Source,
  TimeID,
  SiteSection,
  SEMForm,
  CASE
    WHEN Channel = 'Email' AND url LIKE '%apfmnewsletterb%'
    THEN 'APFM Newsletter B'
    WHEN Channel = 'Email' AND url LIKE '%specialofferb%'
    THEN 'Special Offers B'
    WHEN Channel = 'Email' AND url LIKE '%supportivesaturdayb%'
    THEN 'Supportive Saturday B'
    WHEN Channel = 'Email' AND url LIKE '%dailyb%'
    THEN 'Daily Questions B'
    WHEN Channel = 'Email' AND url LIKE '%newsletterb%'
    THEN 'Newsletter B'
    WHEN Channel = 'Email' AND url LIKE '%apfmnewsletter%'
    THEN 'APFM Newsletter'
    WHEN Channel = 'Email' AND url LIKE '%specialoffer%'
    THEN 'Special Offers'
    WHEN Channel = 'Email' AND url LIKE '%supportivesaturday%'
    THEN 'Supportive Saturday'
    WHEN Channel = 'Email' AND url LIKE '%daily%'
    THEN 'Daily Questions'
    WHEN Channel = 'Email' AND url LIKE '%newsletter%'
    THEN 'Newsletter'
    WHEN Channel = 'Email' AND url LIKE '%ACNurtureb%'
    THEN 'ACNurture B'
    WHEN Channel = 'Email' AND url LIKE '%ACNurture%'
    THEN 'ACNurture'
    WHEN Channel = 'Email' AND affiliateID = 111
    THEN 'Email Inbound'
    ELSE NULL
  END AS EmailType, /* ,url */
  RequestDateTime,
  RequestStatusID,
  Lead,
  LSTF,
  RL,
  RIGHT(campaign1, LENGTH(campaign1) - LOCATE('campaignid=', campaign1) - 10) AS CampaignID
FROM CTEB
LEFT JOIN (
  SELECT
    hmcrequestid,
    ROW_NUMBER() OVER (PARTITION BY hmcrequestid ORDER BY createdate) AS rn,
    userid,
    CASE
      WHEN userid = 1702946
      AND DATEDIFF(
        MINUTE,
        LAG(createdate) OVER (PARTITION BY sr.hmcrequestid ORDER BY hmcscreeningresultid),
        createdate
      ) < 480
      AND LAG(outcomeid) OVER (PARTITION BY sr.hmcrequestid ORDER BY hmcscreeningresultid) IN (12, 13, 14, 16, 17, 22, 24)
      THEN 1
      ELSE 0
    END AS APFMMisattribute
  FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
  WHERE
    createdate >= '2023-11-01'
) AS sr
  ON sr.hmcrequestid = CTEB.hmcrequestid AND rn = 1
WHERE
  Channel <> 'APFM DQ' AND Channel <> 'APFM' AND requeststatusid <> 1
