-- Power BI query shape 334 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            28
-- Distinct texts        6 (same query, different literals or projection)
-- Rows read             288,228,609
-- Rows returned         19,515,528
-- Avg duration          1,376 ms
-- Power BI datasets     none recorded
-- Tables                grace.grace_prod_public.consumer, grace.grace_prod_public.lead, grace.grace_prod_public.referral, grace.grace_prod_public.referral_cart_map, grace.posthog_prod.events, prod.dim_funnel_channel, prod.funnel_lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.affiliate, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcr.postalcode,
    hmcr.affiliateid,
    hmcr.affiliateinquiryid,
    apfm.lt_form_submit_channel,
    CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
    CASE
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
    hmcr.createdate > '2022-01-01'
    AND (
      rn = 1 OR sr.hmcrequestid IS NULL
    )
    AND (
      hmcr.affiliateid <> 140 OR hmcr.postalcode <> 99732
    )
), CTE2 AS (
  SELECT
    CTE.HMCRequestID,
    HMCProspectID,
    affiliateID,
    outcomeid,
    IsDJ,
    formname,
    DJStep,
    djstepid,
    DJType,
    Flow,
    TimeID,
    grace_email.utm_source,
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
      WHEN NOT grace_email.hmcrequestid IS NULL
      THEN 'Email'
      ELSE affiliatename
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
      WHEN (
        LOWER(url) LIKE '%local/%' AND LOWER(url) LIKE '%in-home-car%'
      )
      THEN 'Destination Pages: In Home Care'
      WHEN LOWER(url) LIKE '%local/nursing-homes%'
      THEN 'Destination Pages: Nursing Homes'
      WHEN (
        LOWER(url) LIKE '%local/%' AND LOWER(url) LIKE '%senior-living%'
      )
      THEN 'Destination Pages: Senior Living'
      WHEN (
        LOWER(url) LIKE '%local/%' AND LOWER(url) LIKE '%elder-law-attorneys%'
      )
      THEN 'Destination Pages: Elder Law'
      WHEN LOWER(url) LIKE '%products%'
      THEN 'Product Pages'
      WHEN (
        LOWER(url) LIKE '%/signin%'
        OR LOWER(url) LIKE '%/profile%'
        OR LOWER(url) LIKE '%caregiver-forum%'
        OR LOWER(url) LIKE '%topics/number/subject/%'
        OR (
          LOWER(url) LIKE '%question%' AND LENGTH(url) > 10
        )
        OR (
          LOWER(url) LIKE '%discussion%' AND LENGTH(url) > 10
        )
      )
      THEN 'Forum Pages'
      WHEN (
        LOWER(url) LIKE '%topics%' OR LOWER(url) LIKE '%article%'
      )
      THEN 'Article Pages'
      WHEN (
        LOWER(url) LIKE '%agingcare.com' OR LOWER(url) = '/'
      )
      THEN 'HomePage'
      WHEN (
        LOWER(url) LIKE '%local%' AND LENGTH(url) < 10
      )
      OR LOWER(url) LIKE '%/landing-pages/local%'
      OR formname = 'Local'
      THEN '/Local'
      WHEN (
        LOWER(url) LIKE '%local/search%' AND LENGTH(url) < 16
      )
      THEN 'Local Search'
      WHEN (
        (
          LOWER(url) LIKE '%lp/homecare%' OR LOWER(url) LIKE '%/lp/bp-homecare%'
        )
        OR LOWER(url) LIKE '%better-path%'
      )
      THEN 'SEM LP'
      WHEN LOWER(url) LIKE '%caregivers.com/in-home-care%'
      THEN 'Caregivers In Home Care'
      WHEN (
        LOWER(url) LIKE '%local/%' AND LOWER(url) LIKE '%home-care%'
      )
      THEN 'Destination Pages: In Home Care'
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
      WHEN affiliateID = 134
      THEN 'SEM Care.com Challenger Page'
    END AS SEMForm,
    url,
    RequestDateTime,
    RequestStatusID,
    CASE
      WHEN AdjChannel <> 'SEM'
      THEN NULL
      ELSE REGEXP_EXTRACT(SUBSTRING_INDEX(url, 'campaignid=', -1), '([0-9]+)', 0)
    END AS Campaign1,
    Lead,
    LSTF,
    RL
  FROM CTE
  LEFT JOIN (
    SELECT DISTINCT
      hmcr.hmcrequestid, /* ,r.referredon,pr.created_at,e.`timestamp` */
      e.distinct_id AS posthog_distinct_id,
      CAST(e.properties:utm_campaign AS STRING) AS utm_campaign,
      CAST(e.properties:utm_content AS STRING) AS utm_content,
      CAST(e.properties:utm_medium AS STRING) AS utm_medium,
      CAST(e.properties:utm_source AS STRING) AS utm_source
    FROM prod_homecare_insite_directory.hmcrequest AS hmcr
    LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
      ON hmcl.hmcrequestid = hmcr.hmcrequestid
    LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
      ON r.hmcleadid = hmcl.hmcleadid
    LEFT JOIN grace.grace_prod_public.referral_cart_map AS rcm
      ON rcm.cart_referral_id = r.referralid
    LEFT JOIN grace.grace_prod_public.referral AS pr
      ON pr.id = rcm.referral_id
    LEFT JOIN grace.grace_prod_public.lead AS l
      ON l.id = pr.lead_id
    LEFT JOIN grace.grace_prod_public.consumer AS c
      ON c.id = l.consumer_id
    LEFT JOIN grace.posthog_prod.events AS e
      ON e.distinct_id = c.account_id
      AND e.event = '$pageview'
      AND DATEDIFF(DAY, e.`timestamp`, pr.created_at) <= 3
      AND DATEDIFF(DAY, e.`timestamp`, pr.created_at) >= 0
    WHERE
      hmcr.requeststatusid = 2
      AND hmcr.createdate >= '2026-03-01'
      AND hmcr.affiliateid = 140
      AND CAST(e.properties:utm_medium AS STRING) = 'email'
      AND CAST(e.properties:utm_source AS STRING) <> 'grace_welcome'
  ) AS grace_email
    ON grace_email.hmcrequestid = CTE.HMCRequestID
), CTE3 AS (
  SELECT
    HMCRequestID,
    HMCProspectID,
    Flow,
    outcomeid AS lastoutcomeid,
    affiliateID,
    Channel,
    IsDJ,
    DJStep,
    djstepid,
    DJType,
    Source,
    formname,
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
      WHEN Channel = 'Grace' AND Source = 'Email'
      THEN utm_source
      ELSE NULL
    END AS EmailType, /* ,url */
    RequestDateTime,
    RequestStatusID,
    Lead,
    LSTF,
    RL,
    campaign1 AS CampaignID
  FROM CTE2
)
SELECT DISTINCT
  *,
  CASE
    WHEN CampaignID = '18462205639'
    THEN 'MidValueT3'
    WHEN CampaignID = '18462209188'
    THEN 'MidValueT4'
    WHEN CampaignID = '18462209191'
    THEN 'HighValueT4'
    WHEN CampaignID = '18931315335'
    THEN 'HighValueT1 _CPA Test'
    WHEN CampaignID = '19088386289'
    THEN 'HighValueT1 _Interested_Test'
    WHEN CampaignID = '19830715574'
    THEN 'MidValueT1'
    WHEN CampaignID = '20159729698'
    THEN 'Mobile - Caregivers - T2'
    WHEN CampaignID = '20159729695'
    THEN 'Mobile - Caregivers - T1'
    WHEN CampaignID = '20108844850'
    THEN 'Desktop - Caregivers - T1'
    WHEN CampaignID = '20131684937'
    THEN 'Desktop - Caregivers - T2'
    WHEN CampaignID = '20156319791'
    THEN 'Non Brand + Location - Caregivers'
    WHEN CampaignID = '20259897987'
    THEN 'Mobile - Home Health Care - T1'
    WHEN CampaignID = '20259897990'
    THEN 'Mobile - Home Health Care - T2'
    WHEN CampaignID = '20259897981'
    THEN 'Desktop - Home Health Care - T1'
    WHEN CampaignID = '20259897984'
    THEN 'Desktop - Home Health Care - T2'
    WHEN CampaignID = '20268857185'
    THEN 'Non Brand + Location - Home Health Care'
    WHEN CampaignID = '20292641246'
    THEN 'Brand - T2'
    WHEN CampaignID = '20292459272'
    THEN 'Desktop - Competitor - T2'
    WHEN CampaignID = '20292459269'
    THEN 'Mobile - Competitor - T1'
    WHEN CampaignID = '20292459275'
    THEN 'Mobile - Competitor - T2'
    WHEN CampaignID = '20329067458'
    THEN 'Non Brand + Location - Elderly Care'
    WHEN CampaignID = '20329003615'
    THEN 'Desktop - Elderly Care - T1'
    WHEN CampaignID = '20329003621'
    THEN 'Mobile - Elderly Care - T1'
    WHEN CampaignID = '20329003618'
    THEN 'Desktop - Elderly Care - T2'
    WHEN CampaignID = '20329003624'
    THEN 'Mobile - Elderly Care - T2'
    WHEN CampaignID = '20326641070'
    THEN 'Non Brand + Location - Home Health Care Agency'
    WHEN CampaignID = '20317140192'
    THEN 'Desktop - Home Health Care Agency - T1'
    WHEN CampaignID = '20317140198'
    THEN 'Mobile - Home Health Care Agency - T1'
    WHEN CampaignID = '20317140195'
    THEN 'Desktop - Home Health Care Agency - T2'
    WHEN CampaignID = '20317140201'
    THEN 'Mobile - Home Health Care Agency - T2'
    WHEN CampaignID = '20320336072'
    THEN 'Non Brand + Location - Nursing'
    WHEN CampaignID = '20320336063'
    THEN 'Desktop - Nursing - T2'
    WHEN CampaignID = '20320336069'
    THEN 'Mobile - Nursing - T2'
    WHEN CampaignID = '20320336060'
    THEN 'Desktop - Nursing - T1'
    WHEN CampaignID = '20320336066'
    THEN 'Mobile - Nursing - T1'
    WHEN CampaignID = '20369918767'
    THEN 'Desktop - Agencies and Orgs - T1'
    WHEN CampaignID = '20369918764'
    THEN 'Desktop - Agencies and Orgs - T2'
    WHEN CampaignID = '20362621598'
    THEN 'Desktop - Care Types - T1'
    WHEN CampaignID = '20362621601'
    THEN 'Desktop - Care Types - T2'
    WHEN CampaignID = '20369918638'
    THEN 'Mobile - Agencies and Orgs - T1'
    WHEN CampaignID = '20369918761'
    THEN 'Mobile - Agencies and Orgs - T2'
    WHEN CampaignID = '20362621604'
    THEN 'Mobile - Care Types - T1'
    WHEN CampaignID = '20362621607'
    THEN 'Mobile - Care Types - T2'
    WHEN CampaignID = '638297940'
    THEN 'Desktop - Home Health Care - T1'
    WHEN CampaignID = '638297906'
    THEN 'Desktop - Home Health Care - T2'
    WHEN CampaignID = '638297907'
    THEN 'Desktop - Nursing - T1'
    WHEN CampaignID = '638297941'
    THEN 'Desktop - Nursing - T2'
    WHEN CampaignID = '20370848139'
    THEN 'GEO Target - Caregivers - DMA_GA_Atlanta'
    WHEN CampaignID = '20370848136'
    THEN 'GEO Target - Caregivers - DMA_PA_Philadelphia'
    WHEN CampaignID = '20470958800'
    THEN 'GEO Target - Non Brand - DMA_IL_Chicago'
    WHEN CampaignID = '20477205771'
    THEN 'GEO Target - Non Brand - DMA_NY_New-York'
    WHEN CampaignID = '638312122'
    THEN 'MMA - Competitor - T1'
    WHEN CampaignID = '20497793452'
    THEN 'GEO Target - Non Brand - DMA_FL_Jacksonville'
    WHEN CampaignID = '20497793455'
    THEN 'GEO Target - Non Brand - DMA_FL_Orlando'
    WHEN CampaignID = '20501681418'
    THEN 'GEO Target - Non Brand - DMA_TX_Dallas_FW'
    WHEN CampaignID = '20501681421'
    THEN 'GEO Target - Non Brand - DMA_TX_Houston'
    WHEN CampaignID = '20536542696'
    THEN 'APFM Brand - T1'
    WHEN CampaignID = '20546095819'
    THEN 'APFM Brand - T2'
    WHEN CampaignID = '63843060'
    THEN 'Partners - Caregivers - T1'
    WHEN CampaignID = '638388470'
    THEN 'Partners - Home Health Care Agency - T1'
    WHEN CampaignID = '638388471'
    THEN 'Partners - Elderly Care - T2'
    WHEN CampaignID = '638388472'
    THEN 'Partners - Elderly Care - T1'
    WHEN CampaignID = '638388473'
    THEN 'Partners - Care Types - T2'
    WHEN CampaignID = '638388474'
    THEN 'Partners - Care Types - T1'
    WHEN CampaignID = '638388475'
    THEN 'Partners - Agencies and Orgs - T1'
    WHEN CampaignID = '638388476'
    THEN 'Partners - Agencies and Orgs - T2'
    WHEN CampaignID = '638388477'
    THEN 'Partners - Home Health Care - T1'
    WHEN CampaignID = '638388478'
    THEN 'Partners - Nursing - T2'
    WHEN CampaignID = '638388479'
    THEN 'Partners - Nursing - T1'
    WHEN CampaignID = '638388480'
    THEN 'Partners - Home Health Care - T2'
    WHEN CampaignID = '638388481'
    THEN 'Partners - Caregivers - T2'
    WHEN CampaignID = '638388484'
    THEN 'Partners - Competitor'
    WHEN CampaignID = '638388490'
    THEN 'Partners - Recruitment Leads'
    WHEN CampaignID = '638312122'
    THEN 'MMA - Competitor - T1'
    WHEN CampaignID = '20729495267'
    THEN 'GEO Target - Non Brand - High Reach'
    WHEN CampaignID = '20819400612'
    THEN 'Desktop - Care Types - T1 - APFM Brand'
    WHEN CampaignID = '20848539595'
    THEN 'Desktop - Home Health Care - T1 - APFM Brand'
    WHEN CampaignID = '20829571816'
    THEN 'Mobile - Care Types - T1 - APFM Brand'
    WHEN CampaignID = '20838377430'
    THEN 'Mobile - Home Health Care - T1 - APFM Brand'
    WHEN CampaignID = '20883191214'
    THEN 'Home Care - PMax - T1'
    WHEN CampaignID = '638530323'
    THEN 'Desktop - Competitor - T2'
    WHEN CampaignID = '21149280686'
    THEN 'Partners - Desktop - Care Types - T1'
    WHEN CampaignID = '21142376391'
    THEN 'Partners - Desktop - Care Types - T1 - APFM Brand'
    WHEN CampaignID = '21149280179'
    THEN 'Partners - Desktop - Elderly Care - T1'
    WHEN CampaignID = '21142377831'
    THEN 'Partners - Desktop - Agencies and Orgs - T1'
    WHEN CampaignID = '21152743894'
    THEN 'Partners - Desktop - Home Health Care - T1'
    WHEN CampaignID = '21142376379'
    THEN 'Partners - Desktop - Home Health Care Agency - T1'
    WHEN CampaignID = '21149280227'
    THEN 'Partners - Desktop - Caregivers - T1'
    WHEN CampaignID = '21149280908'
    THEN 'Partners - Desktop - Nursing - T1'
    WHEN CampaignID = '21152744542'
    THEN 'Partners - Desktop - Home Health Care - T1 - APFM Brand'
    WHEN CAMPAIGNID = '382714049'
    THEN 'Recruitment Leads'
    WHEN CAMPAIGNID = '427143807'
    THEN 'HighValueT1'
    WHEN CAMPAIGNID = '427143808'
    THEN 'HighValueT2'
    WHEN CAMPAIGNID = '427143810'
    THEN 'MidValueT2'
    WHEN CAMPAIGNID = '427143811'
    THEN 'Brand'
    WHEN CAMPAIGNID = '427143812'
    THEN 'Competitor'
    WHEN CAMPAIGNID = '638281222'
    THEN 'Desktop - Caregivers - T1'
    WHEN CAMPAIGNID = '638281223'
    THEN 'Desktop - Caregivers - T2'
    WHEN CAMPAIGNID = '638302606'
    THEN 'Desktop - Home Health Care - T1'
    WHEN CAMPAIGNID = '638308099'
    THEN 'Desktop - Agencies and Orgs - T2'
    WHEN CAMPAIGNID = '638308104'
    THEN 'Desktop - Agencies and Orgs - T1'
    WHEN CAMPAIGNID = '638309670'
    THEN 'Desktop - Care Types - T1'
    WHEN CAMPAIGNID = '638309673'
    THEN 'Desktop - Care Types - T2'
    WHEN CAMPAIGNID = '638309679'
    THEN 'Desktop - Elderly Care - T1'
    WHEN CAMPAIGNID = '638309680'
    THEN 'Desktop - Elderly Care - T2'
    WHEN CAMPAIGNID = '638311984'
    THEN 'Desktop - Home Health Care Agency - T1'
    WHEN CAMPAIGNID = '638312089'
    THEN 'Desktop - Home Health Care Agency - T2'
    WHEN CAMPAIGNID = '638388469'
    THEN 'Partners - Home Health Care Agency - T2'
    WHEN CAMPAIGNID = '16867706577'
    THEN 'HighValueT1'
    WHEN CAMPAIGNID = '16867706583'
    THEN 'MidValueT1'
    WHEN CAMPAIGNID = '16867706589'
    THEN 'Brand'
    WHEN CAMPAIGNID = '16867706592'
    THEN 'Competitor'
    WHEN CAMPAIGNID = '21358667734'
    THEN 'NB:NAT:Hospice Care:T1'
    WHEN CAMPAIGNID = '21358667728'
    THEN 'NB:NAT:Hospice Care:T1:Exact'
    WHEN CAMPAIGNID = '21358667737'
    THEN 'NB:NAT:Respite Care:T1:Broad'
    WHEN CAMPAIGNID = '21358667731'
    THEN 'NB:NAT:Respite Care:T1'
    WHEN CAMPAIGNID = '22202164461'
    THEN 'NB:NAT:Partner Network:T1:All'
    WHEN CAMPAIGNID = '22388527326'
    THEN 'Desktop - Agencies and Orgs - T1 DMA_ConvValueMod_Test'
    WHEN CAMPAIGNID = '22398509662'
    THEN 'Desktop - Caregivers - T1 DMA_ConvValueMod_Test'
    ELSE CampaignID
  END AS CampaignName
FROM CTE3
