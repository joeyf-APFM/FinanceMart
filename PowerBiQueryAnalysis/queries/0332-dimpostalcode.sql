-- Power BI query shape 332 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             30,805,061
-- Rows returned         3,659,575
-- Avg duration          6,596 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_actransactional_geo.stateprovince, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hmcr.hmcrequestid,
  hmcr.hmcprospectid,
  hmcr.requeststatusid,
  hmcr.createdate AS LeadCreateDate,
  CASE
    WHEN tz.timezoneid = 4
    THEN CONVERT_TIMEZONE('America/Detroit', 'Pacific/Honolulu', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 6
    THEN CONVERT_TIMEZONE('America/Detroit', 'US/Alaska', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 10
    THEN CONVERT_TIMEZONE('America/Detroit', 'US/Pacific', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 13
    THEN CONVERT_TIMEZONE('America/Detroit', 'America/Boise', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 15
    THEN CONVERT_TIMEZONE('America/Detroit', 'America/Chicago', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 26
    THEN CONVERT_TIMEZONE('America/Detroit', 'America/Glace_Bay', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    WHEN tz.timezoneid = 20
    THEN CONVERT_TIMEZONE('America/Detroit', 'America/Detroit', CAST(hmcr.createdate AS TIMESTAMP_NTZ))
    ELSE hmcr.createdate
  END AS TimeZone_CreateDate,
  CASE
    WHEN djstepid < 100
    THEN 'Started in DJ'
    WHEN djstepid = 100
    THEN 'Referred by DJ'
    ELSE NULL
  END AS DigitalJourney,
  hmcr.postalcode,
  sp.Name AS State,
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
    WHEN hmcr.affiliateID IN (90, 107, 113, 133)
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
  END AS AdjChannel
FROM prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
  ON pc.code = TRIM(hmcr.postalcode)
LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
  ON tz.timezoneid = pc.timezoneid
LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
  ON sp.stateprovinceid = pc.stateprovinceid
WHERE
  NOT djstepid IS NULL
