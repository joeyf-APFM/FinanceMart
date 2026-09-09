-- Power BI query shape 435 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             10,172,968
-- Rows returned         801,807
-- Avg duration          721 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    DATE_ADD(SECOND, -sr.SecondsInProspect, sr.createdate) AS ScreeningStartDateTime,
    DATEDIFF(SECOND, hmcr.createdate, DATE_ADD(SECOND, -sr.SecondsInProspect, sr.createdate)) AS FirstScreeningLagSeconds,
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
      WHEN hmcr.affiliateID IN (90, 113, 133, 107)
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
    hmcr.requeststatusid,
    sr.outcomeid,
    sr.createdate AS ScreeningDateTime,
    hmcr.postalcode,
    hmcr.createdate AS RequestDateTime,
    tz.systimezone,
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
    END AS Adjust_CreateDate
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
      AND createdate >= '2024-08-01'
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  WHERE
    hmcr.createdate >= '2024-08-01'
)
SELECT
  *,
  CASE
    WHEN (
      HOUR(Adjust_CreateDate) * 60 + MINUTE(Adjust_CreateDate)
    ) BETWEEN (
      8 * 60 + 30
    ) AND (
      22 * 60
    )
    THEN 1
    ELSE 0
  END AS DuringOperatingHours,
  HOUR(Adjust_CreateDate) AS RequestHour,
  HOUR(ScreeningDateTime) AS ScreeningHour,
  CASE
    WHEN HOUR(Adjust_CreateDate) IN (8, 9, 10, 11)
    THEN 'Morning'
    WHEN HOUR(Adjust_CreateDate) IN (12, 1, 2, 3, 4)
    THEN 'Afternoon'
    WHEN HOUR(Adjust_CreateDate) IN (5, 6, 7, 8)
    THEN 'Evening'
    ELSE 'Other'
  END AS TOD,
  DATE_FORMAT(
    DATE_ADD(
      MINUTE,
      FLOOR(DATEDIFF(MINUTE, '1900-01-01', RequestDateTime) / 30) * 30,
      '1900-01-01'
    ),
    'HH:mm:ss'
  ) AS RequestHalfHour,
  DATEDIFF(SECOND, RequestDateTime, ScreeningStartDateTime) AS SecondstoFirstScreen,
  CASE
    WHEN DATEDIFF(SECOND, RequestDateTime, ScreeningStartDateTime) > 60
    THEN hmcrequestid
    ELSE NULL
  END AS Delayed60,
  CASE
    WHEN DATEDIFF(SECOND, RequestDateTime, ScreeningStartDateTime) > 180
    THEN hmcrequestid
    ELSE NULL
  END AS Delayed180
FROM CTE
WHERE
  NOT AdjChannel IN ('APFM', 'APFM DQ') AND NOT FirstScreeningLagSeconds IS NULL
