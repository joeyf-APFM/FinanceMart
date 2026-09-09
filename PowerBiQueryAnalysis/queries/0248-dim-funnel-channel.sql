-- Power BI query shape 248 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            146
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,350,946,423
-- Rows returned         612,918,235
-- Avg duration          14,563 ms
-- Power BI datasets     none recorded
-- Tables                prod.dim_funnel_channel, prod.funnel_lead, prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcr.affiliateinquiryid,
    apfm.lt_form_submit_channel,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
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
      WHEN hmcr.affiliateID = 112 AND apfm.lt_form_submit_channel = 'SEM'
      THEN 'SEM'
      WHEN hmcr.affiliateid = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid = 138
      THEN 'AgingCare Manual'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    hmcr.affiliateID,
    DATE_FORMAT(hmcr.createdate, 'HH') AS hours,
    DATE_FORMAT(hmcr.createdate, 'mm') AS minute,
    (
      hours * 100
    ) + minute AS TimeID,
    hmcr.url,
    aff.affiliatename,
    CASE WHEN NOT hmcr.djstepid IS NULL THEN 'Started in DJ' ELSE 'Not DJ' END AS ISDJ,
    CASE
      WHEN NOT hmcr.djstepid IS NULL AND hmcr.djstepid <> 100
      THEN 'Dropped From DJ'
      WHEN hmcr.djstepid = 100
      THEN 'Completed in DJ'
    END AS DJStep,
    hmcr.djstepid,
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
    sr.outcomeid,
    formname,
    CAST(hmcr.createdate AS DATE) AS RequestDateTime,
    hmcr.RequestStatusID,
    1 AS Lead,
    CASE WHEN hmcr.RequestStatusID = 6 THEN 0 ELSE 1 END AS LSTF,
    CASE WHEN hmcr.RequestStatusID = 2 THEN 1 ELSE 0 END AS RL
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.affiliate AS aff
    ON aff.affiliateid = hmcr.affiliateid
  LEFT JOIN (
    SELECT
      hmcrequestid,
      hmcprospectid,
      outcomeid,
      userid,
      createdate,
      ROW_NUMBER() OVER (PARTITION BY hmcrequestid ORDER BY hmcscreeningresultid DESC) AS rn
    FROM prod_homecare_insite_directory.hmcscreeningresult
    WHERE
      outcomeid IN (12, 13, 14, 16, 17, 18, 20, 22, 24)
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN (
    SELECT
      fl.beacon_inquiry_id,
      TO_DATE(FROM_UTC_TIMESTAMP(CAST(fl.inquiry_created_at AS TIMESTAMP), 'America/New_York')) AS inquiry_created_date_EST,
      fl.inquiry_method,
      fl.status,
      fl.close_inquiry_reason,
      dfc.lt_form_submit_channel,
      dfc.lt_form_submit_sub_channel,
      dfc.lt_form_submit_domain,
      dfc.lt_form_submit_utm_campaign
    FROM prod.funnel_lead AS fl
    LEFT JOIN prod.dim_funnel_channel AS dfc
      ON fl.funnel_lead_id = dfc.funnel_lead_id
    WHERE
      fl.is_default_exclusion IS FALSE
      AND LOWER(status) = 'closed'
      AND LOWER(close_inquiry_reason) LIKE '%sent to leadqueue%'
      AND TO_DATE(FROM_UTC_TIMESTAMP(CAST(fl.inquiry_created_at AS TIMESTAMP), 'America/New_York')) >= '2025-03-16'
  ) AS apfm
    ON apfm.beacon_inquiry_id = hmcr.affiliateinquiryid
  WHERE
    hmcr.createdate > '2022-01-01' AND (
      rn = 1 OR sr.hmcrequestid IS NULL
    )
)
SELECT
  HMCRequestID,
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
    WHEN affiliateID = 112 AND lt_form_submit_channel = 'SEM'
    THEN 'APFM SEM'
    WHEN affiliateID = 112 AND lt_form_submit_channel <> 'SEM'
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
    WHEN (
      AdjChannel = 'SEM' AND url LIKE '%msclkid%'
    )
    OR (
      AdjChannel = 'SEM' AND url LIKE '%utm_source=bing%'
    )
    THEN 'SEM - Bing'
    WHEN (
      AdjChannel = 'SEM' AND url LIKE '%gclid%'
    )
    OR (
      AdjChannel = 'SEM' AND url LIKE '%gad_source%'
    )
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
  Lead,
  LSTF,
  RL
FROM CTE
