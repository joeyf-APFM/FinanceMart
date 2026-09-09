-- Power BI query shape 392 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             98,159,148
-- Rows returned         2,667,012
-- Avg duration          9,007 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospectnotes, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult, prod_homecare_insite_directory.hmcscreenqueue
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcrequestid,
    hmcr.hmcprospectid,
    postalcode,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Funnel,
    hmcr.createdate,
    HMCR.RequestStatusId,
    hmcr.requeststatuscode,
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
    END AS AdjChannel,
    sr.createdate AS ScreeningDate,
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
    AttemptCount,
    sr.userid,
    sr.outcomeid,
    pn.Note,
    a.affiliatename,
    hmcr.affiliateID,
    sq.hmcscreenqueueid,
    CASE WHEN NOT hmcr.djstepid IS NULL THEN 'Started in DJ' ELSE 'Not DJ' END AS ISDJ,
    CASE
      WHEN NOT hmcr.djstepid IS NULL AND hmcr.djstepid <> 100
      THEN 'Dropped From DJ'
      WHEN hmcr.djstepid = 100
      THEN 'Completed in DJ'
    END AS DJStep,
    hmcr.djstepid,
    hmcr.affiliateid,
    CASE
      WHEN hmcr.djtypeid = 1
      THEN 'SEM After Hours'
      WHEN hmcr.djtypeid = 2
      THEN 'Re-Engagement Text'
      WHEN hmcr.djtypeid = 3
      THEN 'Re-Engagement Email'
      WHEN hmcr.djtypeid = 4
      THEN 'SEM In-Hours'
      WHEN hmcr.djtypeid = 5
      THEN 'SEO ADJ'
      WHEN hmcr.djtypeid = 6
      THEN 'SEO IDJ'
    END AS DJType,
    hmcr.url,
    ROW_NUMBER() OVER (PARTITION BY hmcr.hmcrequestid ORDER BY sr.hmcscreeningresultid DESC) AS rn
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmclead AS l
    ON l.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN (
    SELECT
      *,
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
      NOT outcomeid IN (5, 15, 19) AND createdate >= '2023-11-01'
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN prod_homecare_insite_directory.hmcscreenqueue AS sq
    ON sq.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  JOIN prod_homecare_insite_directory.affiliate AS a
    ON a.affiliateID = hmcr.affiliateid
  LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
    ON tz.timezoneid = pc.timezoneid
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
  ) AS pn
    ON pn.HMCProspectID = hmcr.HMCProspectID
    AND CAST(pn.CreateDate AS DATE) = CAST(sr.createdate AS DATE)
    AND pn.rns = 1
  WHERE
    (
      NOT sr.outcomeid IN (5, 15, 19) OR sr.outcomeid IS NULL
    )
    AND hmcr.createdate >= '2024-01-01'
    AND sr.APFMMisattribute = 0
), CTE1 AS (
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
    rn = 1
  ORDER BY
    hmcrequestid DESC
), CTE2 AS (
  SELECT
    CTE1.*,
    RIGHT(campaign1, LENGTH(campaign1) - LOCATE('campaignid=', campaign1) - 10) AS CampaignID
  FROM CTE1
)
SELECT
  CTE2.*
  EXCEPT (hmcprospectid, postalcode, affiliatename, url, requeststatuscode, rn, note, affiliateid, source, campaign1, campaignid, Adjust_CreateDate, AttemptCount, djstepid, outcomeid, hmcscreenqueueid),
  CASE
    WHEN AdjChannel = 'SEM'
    AND CampaignID IN (
      21152744542,
      21149280686,
      21142376391,
      21142377831,
      21142376379,
      21149280908,
      21149280227,
      21152743894,
      21149280179,
      638388490,
      638388484,
      638388481,
      638388480,
      638388479,
      638388478,
      638388477,
      638388476,
      638388475,
      638388474,
      638388473,
      638388472,
      638388471,
      638388470,
      638388469,
      638343060
    )
    THEN 'Partner Campaigns'
    WHEN AdjChannel = 'SEM' AND CampaignID IN (20883191214, 638662372)
    THEN 'PMax Campaigns'
    WHEN AdjChannel = 'SEM' AND CampaignID IS NULL
    THEN 'Blank'
    WHEN AdjChannel = 'SEM'
    THEN 'Core Campaigns'
    ELSE Source
  END AS SourceP
FROM CTE2
