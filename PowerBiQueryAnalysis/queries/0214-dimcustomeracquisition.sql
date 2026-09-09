-- Power BI query shape 214 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,557,704,736
-- Rows returned         51,060,715
-- Avg duration          7,075 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hcrs.RequestID,
  hmcr.HMCProspectID,
  hmcr.postalcode,
  dhcr.CustomerAcquisitionKey,
  dca.Source AS oSource,
  CASE
    WHEN hmcr.affiliateID IN (98, 100, 101, 102, 103, 104, 105, 109, 110)
    THEN 'SEM'
    WHEN hmcr.affiliateID = 87
    THEN 'SEO'
    WHEN hmcr.affiliateID = 92
    THEN 'SEO'
    WHEN hmcr.affiliateID = 90
    THEN 'Affiliates'
    WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108)
    THEN 'APFM DQ'
    WHEN hmcr.url LIKE '%msclkid%'
    OR hmcr.url LIKE '%gclid%'
    OR hmcr.url LIKE '%campaignid%'
    THEN 'SEM'
    WHEN hmcr.url LIKE '%email%'
    THEN 'Email'
    WHEN dca.Source IN ('AgingCare', 'Caregivers.com')
    OR hmcr.url LIKE '%/local%'
    OR hmcr.url LIKE '%local/%'
    THEN 'SEO'
    WHEN dca.Source = 'APFM Screened Leads'
    THEN 'APFM'
    WHEN hmcr.affiliateid = 72
    THEN 'APFM'
    WHEN hmcr.url IS NULL AND dca.Source = 'AgingCare - Google'
    THEN 'Unknown'
    ELSE 'Affiliates'
  END AS AdjChannel,
  hmcr.url,
  hmcr.affiliateID,
  hcrs.RequestDateTime,
  dhcr.RequestDateID,
  LastOutcomeDateID,
  LastOutcomeTypeID,
  ScreeningCompleteDateID,
  ProvidersInAreaStart,
  ProvidersInAreaEnd,
  dhcr.RequestStatusID,
  1 AS Lead,
  CASE WHEN LastOutcomeTypeID IS NULL AND dhcr.RequestStatusID = 6 THEN 0 ELSE 1 END AS LSTF,
  CASE WHEN dhcr.RequestStatusID = 2 THEN 1 ELSE 0 END AS RL
FROM prod_homecare_acreporting_reporting.facthomecarerequestsummary AS hcrs
LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
  ON hcrs.RequestID = dhcr.RequestID
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.HMCRequestID = hcrs.RequestID
LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
  ON dca.CustomerAcquisitionKey = dhcr.CustomerAcquisitionKey
WHERE
  hmcr.createdate >= DATE_ADD(MONTH, -3, CURRENT_TIMESTAMP())
  AND NOT affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108)
