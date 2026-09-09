-- Power BI query shape 224 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,359,313,202
-- Rows returned         770,039,743
-- Avg duration          10,632 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimcampaign, prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_insite_directory.hmclead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  hcrs.RequestID,
  dhcr.RequestDateID,
  hcrs.RequestDateTime,
  dhcr.CustomerAcquisitionKey,
  LastCareAdvisorInternalUserKey,
  LastOutcomeTypeID,
  ScreeningCompleteDateID,
  ScreeningCompleteDateTime,
  ScreeningAttemptCount,
  ProvidersInAreaStart,
  ProvidersInAreaEnd,
  dhcr.RequestStatusID,
  hmcl.HotTransferred
FROM prod_homecare_acreporting_reporting.facthomecarerequestsummary AS hcrs
JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
  ON hcrs.RequestID = dhcr.RequestID
LEFT JOIN (
  SELECT
    HMCRequestID,
    HotTransferred,
    ROW_NUMBER() OVER (PARTITION BY HMCRequestID ORDER BY HotTransferred DESC) AS rn
  FROM prod_homecare_insite_directory.hmclead AS hmcl
  WHERE
    YEAR(CreateDate) >= YEAR(DATE_ADD(YEAR, -2, CURRENT_TIMESTAMP()))
) AS hmcl
  ON hmcl.HMCRequestID = hcrs.RequestID AND rn = 1
LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
  ON dca.CustomerAcquisitionKey = dhcr.CustomerAcquisitionKey
LEFT JOIN prod_homecare_acreporting_reporting.dimcampaign AS dc
  ON dc.CampaignKey = dca.CampaignKey
WHERE
  RequestDateID > 20220000
  AND dca.Source NOT LIKE 'APFM Screened Leads'
  AND (
    dc.CampaignName <> 'Recruitment Leads' OR dc.CampaignName IS NULL
  )
ORDER BY
  RequestID DESC
