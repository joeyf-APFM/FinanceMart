-- Power BI query shape 167 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            294
-- Distinct texts        11 (same query, different literals or projection)
-- Rows read             5,333,542,822
-- Rows returned         585,882,607
-- Avg duration          26,880 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_acreporting_reporting.dimtimezone, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospectnotes, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult, prod_homecare_insite_directory.hmcscreenqueue
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcrequestid,
    hmcr.hmcprospectid,
    postalcode,
    CASE WHEN customflow = 1 THEN 'NFE' ELSE 'OFE' END AS Funnel,
    hmcr.createdate,
    HMCR.RequestStatusId,
    hmcr.requeststatuscode,
    sr.createdate AS ScreeningDate,
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
    END AS Adjust_CreateDate,
    AttemptCount,
    sr.userid,
    sr.outcomeid,
    pn.Note,
    hmcr.affiliateID,
    sq.hmcscreenqueueid,
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
    DATE_FORMAT(hmcr.createdate, 'HH') AS hours,
    DATE_FORMAT(hmcr.createdate, 'mm') AS minute,
    (
      hours * 100
    ) + minute,
    ROW_NUMBER() OVER (PARTITION BY hmcr.hmcrequestid ORDER BY sr.hmcscreeningresultid DESC) AS rn
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN prod_homecare_insite_directory.hmclead AS l
    ON l.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN (
    SELECT
      *,
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
      NOT outcomeid IN (5, 15, 19) AND createdate >= '2023-11-01'
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN prod_homecare_insite_directory.hmcscreenqueue AS sq
    ON sq.hmcrequestid = hmcr.hmcrequestid
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pc
    ON pc.code = TRIM(hmcr.postalcode)
  LEFT JOIN prod_homecare_acreporting_reporting.dimtimezone AS tz
    ON tz.timezoneid = pc.timezoneid
  LEFT JOIN (
    SELECT
      HMCProspectID,
      CreateDate,
      Note,
      NoteID,
      Action,
      ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY CreateDate DESC) AS rns
    FROM prod_homecare_insite_directory.hmcprospectnotes
    WHERE
      Action NOT LIKE 'Disqualified'
      AND Action IN ('Answered Call', 'Responded to Email/Sms', 'Called In')
  ) AS pn
    ON pn.HMCProspectID = hmcr.HMCProspectID
    AND CAST(pn.CreateDate AS DATE) = CAST(sr.createdate AS DATE)
    AND pn.rns = 1
  WHERE
    (
      NOT sr.outcomeid IN (5, 15, 19) OR sr.outcomeid IS NULL
    )
    AND hmcr.createdate >= '2025-01-01'
    AND sr.APFMMisattribute = 0
)
SELECT
  *,
  DATE_FORMAT(
    DATE_ADD(MINUTE, FLOOR(DATEDIFF(MINUTE, '1900-01-01', createdate) / 30) * 30, '1900-01-01'),
    'HH:mm:ss'
  ) AS RequestHalfHour,
  HOUR(createdate) AS RequestHour,
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
  END AS DuringOperatingHours
FROM CTE
WHERE
  rn = 1
ORDER BY
  hmcrequestid DESC
