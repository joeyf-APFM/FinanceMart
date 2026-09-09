-- Power BI query shape 156 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            305
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,384,645,546
-- Rows returned         178,153,233
-- Avg duration          29,778 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
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
        122,
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
      WHEN hmcr.affiliateID = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    hmcr.requeststatusid,
    hmcr.postalcode,
    hmcr.createdate,
    hmcr.affiliateid
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
    ON tz.timezoneid = pc.timezoneid
  LEFT JOIN (
    SELECT
      hmcrequestid,
      hmcprospectid,
      outcomeid,
      userid,
      createdate,
      secondsinprospect
    FROM prod_homecare_insite_directory.hmcscreeningresult
    WHERE
      NOT outcomeid IN (14, 15)
      AND NOT secondsinprospect IS NULL
      AND attemptcount = 1
      AND createdate >= '2024-10-01'
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  WHERE
    hmcr.createdate >= '2024-10-01'
)
SELECT
  hmcr.HMCRequestID,
  psc.PostalCode,
  cph.Date,
  COUNT(
    DISTINCT CASE
      WHEN cph.ProviderName LIKE '%Home Instead%'
      OR cph.ProviderName LIKE '%Senior Helpers%'
      THEN cph.ProviderID
      ELSE NULL
    END
  ) AS HISHCount,
  COUNT(DISTINCT CASE WHEN p.NoWarmTransferAllowed = 0 THEN cph.ProviderID ELSE NULL END) AS HTProviderCount,
  COUNT(DISTINCT cph.ProviderID) AS Provider
FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
LEFT JOIN prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.ProviderID = cph.ProviderID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.ProviderID = cph.ProviderID
LEFT JOIN CTE AS hmcr
  ON CAST(hmcr.createdate AS DATE) = cph.Date AND hmcr.postalcode = psc.postalcode
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.HMCRequestID = hmcr.HMCRequestID
LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
  ON pc.code = TRIM(hmcr.postalcode)
LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
  ON tz.timezoneid = pc.timezoneid
WHERE
  hmcr.requeststatusid <> 6
  AND Date >= '2024-10-01'
  AND OrderStatus = 'Active'
  AND psc.Deleted = 0
  AND hmcr.createdate >= '2024-10-01'
  AND NOT hmcr.affiliateid IN (72, 93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
GROUP BY
  psc.PostalCode,
  Date,
  hmcr.HMCRequestID
