-- Power BI query shape 299 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,109,576,994
-- Rows returned         282,728,135
-- Avg duration          11,287 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimcampaign, prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimform, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.dimhomecarescreeningoutcometype, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreenqueue
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hcrs.RequestID,
    hmcr.HMCProspectID,
    dhcr.CustomerAcquisitionKey,
    dca.Source AS oSource,
    CASE
      WHEN hmcr.url LIKE '%msclkid%' OR hmcr.url LIKE '%gclid%'
      THEN 'SEM'
      WHEN hmcr.url LIKE '%email%'
      THEN 'Email'
      WHEN dca.Source IN ('AgingCare', 'Caregivers.com')
      THEN 'SEO'
      WHEN dca.Source = 'APFM Screened Leads'
      THEN 'APFM'
      ELSE 'Affiliates'
    END AS AdjChannel,
    dhcr.RequestPostalCodeID,
    hmcr.url,
    hcrs.RequestDateTime,
    dhcr.RequestDateID,
    LastOutcomeDateID,
    LastOutcomeTypeID,
    sot.ScreeningOutcomeName,
    ScreeningCompleteDateID,
    ProvidersInAreaStart,
    ProvidersInAreaEnd,
    dhcr.RequestStatusID,
    sq.HMCScreenQueueID,
    1 AS Lead,
    CASE
      WHEN LastOutcomeTypeID IS NULL
      AND sq.HMCScreenQueueID IS NULL
      AND dhcr.RequestStatusID = 6
      THEN 0
      ELSE 1
    END AS LSTF,
    CASE WHEN dhcr.RequestStatusID = 2 THEN 1 ELSE 0 END AS RL
  FROM prod_homecare_acreporting_reporting.facthomecarerequestsummary AS hcrs
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
    ON hcrs.RequestID = dhcr.RequestID
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.HMCRequestID = hcrs.RequestID
  LEFT JOIN prod_homecare_insite_directory.hmcscreenqueue AS sq
    ON sq.HMCRequestID = hcrs.RequestID
  LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
    ON dca.CustomerAcquisitionKey = dhcr.CustomerAcquisitionKey
  LEFT JOIN prod_homecare_acreporting_reporting.dimform AS df
    ON df.FormKey = dhcr.FormKey
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarescreeningoutcometype AS sot
    ON sot.ScreeningOutcomeTypeID = hcrs.LastOutcomeTypeID
  WHERE
    RequestDateID > 20210000
), CTE1 AS (
  SELECT
    CTE.RequestID,
    CTE.HMCProspectID,
    CTE.CustomerAcquisitionKey,
    CTE.oSource,
    CTE.AdjChannel AS Channel,
    CASE
      WHEN AdjChannel = 'SEM' AND url LIKE '%msclkid%'
      THEN 'SEM - Bing'
      WHEN AdjChannel = 'SEM' AND url LIKE '%gclid%'
      THEN 'SEM - Google'
      WHEN AdjChannel = 'SEO' AND CTE.oSource = 'AgingCare'
      THEN 'AgingCare.com'
      WHEN AdjChannel = 'SEO' AND CTE.oSource = 'Caregivers.com'
      THEN 'Caregivers.com'
      WHEN AdjChannel = 'APFM'
      THEN 'APFM Screened Leads'
      WHEN AdjChannel = 'Email'
      THEN 'Email'
      ELSE oSource
    END AS Source,
    CASE
      WHEN AdjChannel <> 'SEO'
      THEN NULL
      WHEN CTE.oSource = 'Caregivers.com'
      THEN NULL
      WHEN url LIKE '%/local/in-home-care%'
      THEN 'In Home Care Page'
      WHEN url = '/local'
      THEN '/local Page'
      WHEN url LIKE '%/local/search%'
      THEN 'Search'
      WHEN url LIKE '%lp/homecare%'
      THEN 'SEM LP'
      WHEN url LIKE '%/local/%' AND LENGTH(url) > 10
      THEN 'Provider Pages'
      ELSE 'Unknown'
    END AS SiteSection,
    RequestPostalCodeID,
    CTE.url,
    CTE.RequestDateTime,
    CTE.RequestDateID,
    LastOutcomeDateID,
    LastOutcomeTypeID,
    CTE.ScreeningOutcomeName,
    ScreeningCompleteDateID,
    CTE.RequestStatusID,
    Lead,
    LSTF,
    RL
  FROM CTE
)
SELECT
  CTE1.RequestID,
  CTE1.HMCProspectID,
  CTE1.CustomerAcquisitionKey,
  CASE WHEN hmcr.customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Flow,
  dc.CampaignKey,
  CTE1.Channel,
  CTE1.Source,
  CTE1.SiteSection,
  dc.CampaignName,
  RequestPostalCodeID,
  CASE
    WHEN CTE1.Channel = 'Email' AND CTE1.url LIKE '%apfmnewsletter%'
    THEN 'APFM Newsletter'
    WHEN CTE1.Channel = 'Email' AND CTE1.url LIKE '%specialoffer%'
    THEN 'Special Offers'
    WHEN CTE1.Channel = 'Email' AND CTE1.url LIKE '%supportivesaturday%'
    THEN 'Supportive Saturday'
    WHEN CTE1.Channel = 'Email' AND CTE1.url LIKE '%daily%'
    THEN 'Daily Questions'
    WHEN CTE1.Channel = 'Email' AND CTE1.url LIKE '%newsletter%'
    THEN 'Newsletter'
    ELSE NULL
  END AS EmailType, /* ,CTE1.url */
  CTE1.RequestDateTime,
  CTE1.RequestDateID,
  LastOutcomeDateID,
  LastOutcomeTypeID, /* ,CTE1.ScreeningOutcomeName */
  ScreeningCompleteDateID,
  CTE1.RequestStatusID,
  Lead,
  LSTF,
  RL,
  CASE WHEN ScreeningOutcomeName LIKE '%Match%' AND RL = 1 THEN 1 ELSE 0 END AS VM_Match
FROM CTE1
LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
  ON dca.CustomerAcquisitionKey = CTE1.CustomerAcquisitionKey
LEFT JOIN prod_homecare_acreporting_reporting.dimcampaign AS dc
  ON dc.CampaignKey = dca.CampaignKey
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.HMCRequestID = CTE1.RequestID
ORDER BY
  RequestDateTime DESC
