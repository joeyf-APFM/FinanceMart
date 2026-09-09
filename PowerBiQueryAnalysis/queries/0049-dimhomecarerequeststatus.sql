-- Power BI query shape 49 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,848
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             56,991,077,390
-- Rows returned         9,345,385,646
-- Avg duration          28,103 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 75a0183c-2c90-4d23-9c69-cdb19108448e, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_acreporting_reporting.dimhomecarerequeststatus, prod_homecare_actransactional_homecare.leadhoursperweek, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectoptionalinfo, prod_homecare_insite_directory.hmcprospectpaymentsource, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    hmcr.hmcprospectid,
    hmcr.url,
    hmcr.createdate,
    hmcr.formname,
    hmcr.affiliateid,
    rs.requeststatus,
    hmcp.gender,
    hmcr.requeststatusid,
    hmcp.age,
    CASE
      WHEN hmcp.hmcwhencareneededid = 1
      THEN 'Immediately'
      WHEN hmcp.hmcwhencareneededid = 2
      THEN 'Within 30 days'
      WHEN hmcp.hmcwhencareneededid = 3
      THEN 'Greater than 30 days'
      WHEN hmcp.hmcwhencareneededid = 4
      THEN 'Unsure'
      WHEN hmcp.hmcwhencareneededid = 5
      THEN 'Within 7 days'
      WHEN hmcp.hmcwhencareneededid = 6
      THEN 'No rush'
    END AS WhenCareNeeded,
    isvet,
    hmcp.besttimetocall,
    requirespublicassistance,
    disqualifier,
    hmcwhencareneededid,
    hmcp.relation,
    CASE
      WHEN hmcp.hoursperweekid = 1
      THEN 'Less than 10'
      WHEN hmcp.hoursperweekid = 2
      THEN '10 to 20'
      WHEN hmcp.hoursperweekid = 3
      THEN '20 to 30'
      WHEN hmcp.hoursperweekid = 4
      THEN '30 to 40'
      WHEN hmcp.hoursperweekid = 5
      THEN '40 to 60'
      WHEN hmcp.hoursperweekid = 6
      THEN '24 Hour Care'
      WHEN hmcp.hoursperweekid = 11
      THEN 'Unsure'
      ELSE 'Unknown'
    END AS HoursPerWeek,
    hmcr.emailaddress,
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
        132
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
    CASE
      WHEN hmcr.djtypeid = 1
      THEN 'SEM After Hours'
      WHEN hmcr.djtypeid = 2
      THEN 'Re-Engagement Text'
      WHEN hmcr.djtypeid = 3
      THEN 'Re-Engagement Email'
      WHEN hmcr.djtypeid = 4
      THEN 'SEM In Hours'
      WHEN hmcr.djtypeid = 5
      THEN 'SEO After Hours'
      WHEN hmcr.djtypeid = 6
      THEN 'SEO In Hours'
    END AS DJType,
    CASE
      WHEN hmcr.djstepid = 100
      THEN 'Completed DJ'
      WHEN hmcr.djstepid <> 100 AND NOT hmcr.djstepid IS NULL
      THEN 'Dropped from DJ'
      ELSE 'Not DJ'
    END AS DJ,
    ps.paymentsourceid,
    lpw.name AS HoursPerWeek2
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectoptionalinfo AS oi
    ON oi.hmcprospectid = hmcp.hmcprospectid
  LEFT JOIN prod_homecare_actransactional_homecare.leadhoursperweek AS lpw
    ON lpw.leadhoursperweekid = hmcr.hoursperweekid
  LEFT JOIN (
    SELECT DISTINCT
      hmcprospectid,
      SORT_ARRAY(
        COLLECT_LIST(
          DISTINCT CASE
            WHEN paymentsourceid = 2
            THEN 'Medicaid'
            WHEN paymentsourceid = 9
            THEN 'Insurance'
            ELSE 'Other'
          END
        )
      ) AS paymentsourceid
    FROM prod_homecare_insite_directory.hmcprospectpaymentsource
    GROUP BY
      hmcprospectid
  ) AS ps
    ON ps.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequeststatus AS rs
    ON rs.requeststatusid = hmcr.requeststatusid
  WHERE
    hmcr.createdate >= '2024'
), CTEA AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    COUNT(DISTINCT ref.referralid) AS Referrals
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    hmcr.createdate >= '2024'
  GROUP BY
    hmcr.hmcrequestid
), CTEB AS (
  SELECT DISTINCT
    hmcr.hmcprospectid,
    COUNT(DISTINCT ref.referralid) AS ProspectReferrals
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    hmcr.createdate >= '2024'
  GROUP BY
    hmcr.hmcprospectid
), CTEC AS (
  SELECT DISTINCT
    hmcl.hmcrequestid,
    ref.referralid,
    ref.providerid,
    CASE
      WHEN NOT ref.activatedon IS NULL AND NOT p.providerorganizationid IS NULL
      THEN 'Franchise'
      WHEN NOT ref.activatedon IS NULL AND p.providerorganizationid IS NULL
      THEN 'Independent'
      ELSE NULL
    END AS ActivationType,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM prod_homecare_insite_directory.hmclead AS hmcl
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
)
SELECT
  CTE.*,
  CASE
    WHEN Referrals = 1
    THEN 1
    WHEN Referrals = 2
    THEN 2
    WHEN Referrals = 3
    THEN 3
    WHEN Referrals = 4
    THEN 4
    WHEN Referrals = 5
    THEN 5
    WHEN Referrals > 5
    THEN '>5'
    ELSE 0
  END AS Referrals,
  CASE
    WHEN ProspectReferrals = 1
    THEN 1
    WHEN ProspectReferrals = 2
    THEN 2
    WHEN ProspectReferrals = 3
    THEN 3
    WHEN ProspectReferrals = 4
    THEN 4
    WHEN ProspectReferrals = 5
    THEN 5
    WHEN ProspectReferrals > 5
    THEN '>5'
    ELSE 0
  END AS ProspectReferrals,
  CTEC.Referralid,
  CTEC.Org,
  ctec.ActivationType
FROM CTE
LEFT JOIN CTEA
  ON CTEA.hmcrequestid = CTE.hmcrequestid
LEFT JOIN CTEB
  ON CTEB.hmcprospectid = CTE.hmcprospectid
LEFT JOIN CTEC
  ON CTEC.hmcrequestid = CTE.hmcrequestid
