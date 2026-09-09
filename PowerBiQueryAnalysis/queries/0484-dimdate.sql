-- Power BI query shape 484 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             39,642,393
-- Rows returned         1,502,992
-- Avg duration          1,037 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, prod_ygl_apfm.region, prod_ygl_apfm.region_use, prod_ygl_apfm.zip_region
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    r.region_id AS regionId,
    r.region_name AS regionName,
    zr.zip5
  FROM main.prod_ygl_apfm.zip_region AS zr
  JOIN main.prod_ygl_apfm.region AS r
    ON r.region_id = zr.region_id
  JOIN main.prod_ygl_apfm.region_use AS ru
    ON ru.region_id = zr.region_id AND ru.region_type_code = zr.region_type_code
  WHERE
    ru.region_type_code = 'ADVISOR'
    AND r.region_name = 'South Texas'
    AND r.active = 1
    AND zr.`_fivetran_deleted` = FALSE
    AND r.`_fivetran_deleted` = FALSE
    AND ru.`_fivetran_deleted` = FALSE
  ORDER BY
    r.region_id,
    zr.zip5
), CTED AS (
  SELECT
    DateID,
    Date,
    DayOfYear,
    DayOfMonth,
    DayOfWeek,
    WeekDayName,
    Month,
    MonthName,
    Year,
    MonthYearID,
    ROW_NUMBER() OVER (PARTITION BY dayofweek, month, year ORDER BY date) AS WeekDay
  FROM prod_homecare_acreporting_reporting.dimdate
  WHERE
    year IN ('2026', '2025')
), CTED1 AS (
  SELECT
    date,
    CONCAT(dayofweek, '-', Weekday) AS DayofWeekNumberMonth
  FROM cted
), cte1 AS (
  SELECT
    CAST(hmcr.createdate AS DATE) AS RequestCreatedate,
    hmcr.hmcrequestid,
    CASE
      WHEN hmcr.djstepid = 100
      THEN 'DJ Completed'
      WHEN hmcr.affiliateid = 72
      THEN 'SLA'
      WHEN hmcr.affiliateid IN (140, 141)
      THEN 'Grace'
      ELSE 'Care Advisor'
    END AS Referredby,
    hmcr.affiliateid,
    hmcr.leadsource,
    ref.referralid,
    hmcr.requeststatusid,
    CASE
      WHEN ref.returnapproved IS TRUE
      THEN 'Returned'
      WHEN ref.returnapproved IS FALSE
      THEN 'Attempted'
      ELSE 'Not Attempted'
    END AS ReturnStatus,
    CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrders,
    CAST(ref.referredon AS DATE) AS ReferralDate,
    CASE
      WHEN DAY(hmcr.createdate) <= 7
      THEN 'First 7'
      WHEN DATEDIFF(DAY, hmcr.createdate, LAST_DAY(hmcr.createdate)) < 6
      THEN 'Last 7'
      ELSE 'Middle'
    END AS TimeFrame,
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
      WHEN hmcr.affiliateID IN (90, 113, 133 /* ,107 */)
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
    DATEDIFF(DAY, requestcreatedate, activatedon) AS DaystoActivation,
    CASE WHEN NOT ref.activatedon IS NULL THEN 'Activated' ELSE 'Not Activated' END AS Activation,
    CAST(ref.activatedon AS DATE) AS ActivationDate,
    htr.referralid AS htrreferral,
    CASE WHEN NOT cte.zip5 IS NULL THEN 'South Texas' ELSE 'Other' END AS PilotGroup,
    CTED1.DayofWeekNumberMonth
  FROM CTED1
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON CAST(hmcr.createdate AS DATE) = CTED1.date
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid AND ref.billingtypeid = 3
  LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
    ON htr.referralid = ref.referralid AND htr.hottransferresponseid = 1
  LEFT JOIN CTE
    ON cte.zip5 = hmcr.postalcode
  WHERE
    hmcr.createdate >= '2026'
), CTEHT AS (
  SELECT
    hmcr.hmcrequestid
  FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid AND ref.billingtypeid = 3
  LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
    ON htr.referralid = ref.referralid
  WHERE
    htr.hottransferresponseid = 1
)
SELECT
  cte1.*,
  CASE
    WHEN Referredby = 'Care Advisor' AND NOT cteht.hmcrequestid IS NULL
    THEN 'CA HT'
    WHEN Referredby = 'Care Advisor'
    THEN 'CA Not HT'
    WHEN Referredby = 'SLA' AND LOWER(leadsource) = 'api'
    THEN 'HCOnly'
    WHEN Referredby = 'SLA'
    THEN 'HC+SL'
    ELSE NULL
  END AS referredbysource
FROM CTE1
LEFT JOIN CTEHT
  ON CTEHT.hmcrequestid = cte1.hmcrequestid
