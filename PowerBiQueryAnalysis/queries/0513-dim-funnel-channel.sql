-- Power BI query shape 513 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             166,329,855
-- Rows returned         7,581,042
-- Avg duration          14,020 ms
-- Power BI datasets     none recorded
-- Tables                prod.dim_funnel_channel, prod.funnel_lead, prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.hmcoutcomes, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectdisqualifier, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcpd.disqualifier AS Disqualifier2,
    hmcp.disqualifierreason,
    hmcr.affiliateid
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectdisqualifier AS hmcpd
    ON hmcpd.hmcprospectdisqualifierid = hmcp.disqualifier
), CTE1 AS (
  SELECT
    HMCRequestID,
    HMCProspectID AS HMCProspectID2,
    Disqualifier2,
    disqualifierreason,
    affiliateID AS affiliateID2
  FROM CTE
  WHERE
    affiliateID IN (117)
), CTEA AS (
  SELECT
    hmcr.HMCRequestID,
    hmcr.HMCProspectID,
    hmcpd.disqualifier,
    HMCProspectID2,
    affiliateID2,
    disqualifier2,
    hmcr.requeststatusid,
    hmcp.disqualifierreason,
    hmcr.affiliateID,
    hmcr.createdate AS RequestDateTime,
    hmcr.RequestStatusID,
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
    END AS Channel,
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
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN prod_homecare_insite_directory.hmcprospectdisqualifier AS hmcpd
    ON hmcpd.hmcprospectdisqualifierid = hmcp.disqualifier
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
    ON tz.timezoneid = pc.timezoneid
  LEFT JOIN CTE1
    ON CTE1.hmcprospectid2 = hmcr.hmcprospectid
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
    hmcr.createdate > '2024-01-01' AND (
      rn = 1 OR sr.hmcrequestid IS NULL
    )
), CTEB AS (
  SELECT
    HMCRequestID,
    HMCProspectID,
    HMCProspectID2,
    affiliateID,
    affiliateID2,
    requeststatusid,
    Channel,
    ISDJ,
    DJStep,
    DJType,
    disqualifier,
    DATE_FORMAT(Adjust_CreateDate, 'HH') AS hours,
    DATE_FORMAT(Adjust_CreateDate, 'mm') AS minute,
    (
      hours * 100
    ) + minute AS TimeID,
    disqualifier2,
    disqualifierreason,
    Adjust_CreateDate
  FROM CTEA
), CTE2 /* WHERE Channel <> 'APFM DQ' and Channel <> 'APFM' and --requeststatusid <> 1 */ AS (
  SELECT DISTINCT
    CTEB.HMCRequestID,
    CTEB.HMCProspectID,
    disqualifier,
    Channel,
    userid,
    requeststatusid,
    ISDJ,
    DJStep,
    DJType,
    adjust_createdate,
    DATE_FORMAT(Adjust_CreateDate, 'HH:mm') AS Time,
    CASE
      WHEN requeststatusid = 4
      THEN 'Max Attempts'
      WHEN CTEB.HMCProspectID = HMCProspectID2 AND affiliateid2 IN (117)
      THEN 'Resistant to Referral'
      WHEN CTEB.HMCProspectID IS NULL AND requeststatusid = 3
      THEN 'Misdirected Request'
      WHEN disqualifier IS NULL AND requeststatusid = 5
      THEN 'Hard Stop'
      WHEN disqualifier IS NULL AND requeststatusid = 7
      THEN 'APFM Matches Ignored'
      WHEN disqualifier IS NULL AND requeststatusid = 8
      THEN 'Duplicated'
      ELSE disqualifier
    END AS disqualifierfixed,
    CASE
      WHEN CTEB.HMCProspectID = HMCProspectID2 AND affiliateid2 IN (117)
      THEN NULL
      ELSE disqualifierreason
    END AS disqualifierreason_fixed,
    disqualifierreason
  FROM CTEB
  LEFT JOIN (
    SELECT
      hmcrequestid,
      ROW_NUMBER() OVER (PARTITION BY hmcrequestid ORDER BY createdate) AS rn,
      userid,
      CASE
        WHEN userid = 1702946
        AND DATEDIFF(
          MINUTE,
          LAG(createdate) OVER (PARTITION BY sr.hmcrequestid ORDER BY hmcscreeningresultid),
          createdate
        ) < 480
        AND LAG(outcomeid) OVER (PARTITION BY sr.hmcrequestid ORDER BY hmcscreeningresultid) IN (12, 13, 14, 16, 17, 22, 24)
        THEN 1
        ELSE 0
      END AS APFMMisattribute
    FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
    WHERE
      createdate >= '2024-01-01'
  ) AS sr
    ON sr.hmcrequestid = CTEB.hmcrequestid AND rn = 1
)
SELECT
  CTE2.*,
  hmcr.firstname AS ContactFirstName,
  hmcr.lastname AS ContactLastName,
  hmcp.createdate AS Prospect_Date,
  hmcr.postalcode,
  sr.Createdate AS ScreeningDate,
  sr.outcomeid AS Outcome,
  o.outcomename AS OutcomeName,
  sr.userid AS Screeninguser
FROM CTE2
LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = CTE2.hmcrequestid
LEFT JOIN main.prod_homecare_insite_directory.hmcprospect AS hmcp
  ON hmcp.hmcprospectid = hmcr.hmcprospectid
LEFT JOIN main.prod_homecare_insite_directory.hmcscreeningresult AS sr
  ON sr.hmcrequestid = hmcr.hmcrequestid
LEFT JOIN main.prod_homecare_insite_directory.hmcoutcomes AS o
  ON o.outcomeid = sr.outcomeid
