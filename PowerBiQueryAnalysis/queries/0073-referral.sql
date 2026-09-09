-- Power BI query shape 73 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,164
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             44,040,714,202
-- Rows returned         5,549,710
-- Avg duration          16,153 ms
-- Power BI datasets     e9d48e9c-bb12-4860-b411-434978fd49fe
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcoutcomes, prod_homecare_insite_directory.hmcprospectnotes, prod_homecare_insite_directory.hmcprospectphonenumber, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    hmcr.hmcprospectid,
    CONCAT(hmcr.firstname, ' ', hmcr.lastname) AS ContactName,
    CAST(hmcr.createdate AS DATE) AS RequestCreateDate,
    hpn.phonenumber,
    1 AS Lead,
    CASE WHEN hmcr.requeststatusid = 6 THEN 0 ELSE 1 END AS LSTF,
    CASE WHEN hmcr.requeststatusid = 2 THEN 1 ELSE 0 END AS RL,
    pn.note,
    CAST(sr.createdate AS DATE) AS ScreeningDate,
    sr.AttemptCount,
    sr.userid,
    sr.outcomeid,
    pn.Note,
    hmcr.affiliateID,
    CONCAT('https://admin.agingcare.com/HMCLeadQueue/Home/Prospect/', hmcr.hmcprospectid) AS ProspectLink,
    ROW_NUMBER() OVER (PARTITION BY hmcr.hmcrequestid ORDER BY sr.hmcscreeningresultid DESC) AS rn
  FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN main.prod_homecare_insite_directory.hmcprospectphonenumber AS hpn
    ON hpn.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN main.prod_homecare_insite_directory.hmcprospectnotes AS pn
    ON pn.hmcprospectid = hmcr.hmcprospectid
  LEFT JOIN (
    SELECT
      sr.*,
      ref.referredon,
      DATEDIFF(
        MINUTE,
        LAG(sr.createdate) OVER (PARTITION BY sr.hmcrequestid ORDER BY sr.hmcscreeningresultid),
        sr.createdate
      ),
      LAG(outcomeid) OVER (PARTITION BY sr.hmcrequestid ORDER BY sr.hmcscreeningresultid) IN (12, 13, 14, 16, 17, 22, 24),
      CASE
        WHEN sr.userid = 1702946
        AND DATEDIFF(
          MINUTE,
          LAG(sr.createdate) OVER (PARTITION BY sr.hmcrequestid ORDER BY sr.hmcscreeningresultid),
          sr.createdate
        ) < 480
        AND LAG(outcomeid) OVER (PARTITION BY sr.hmcrequestid ORDER BY sr.hmcscreeningresultid) IN (12, 13, 14, 16, 17, 22, 24)
        THEN 1
        WHEN sr.userid = 1702946
        AND DATE_FORMAT(sr.createdate, 'MMM-dd-yy HH:mm:ss') > DATE_FORMAT(ref.referredon, 'MMM-dd-yy HH:mm:ss')
        THEN 1
        ELSE 0
      END AS APFMMisattribute
    FROM prod_homecare_insite_directory.hmcscreeningresult AS sr
    LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
      ON hmcl.hmcrequestid = sr.hmcrequestid
    LEFT JOIN main.prod_homecare_actransactional_homecare.referral AS ref
      ON ref.hmcleadid = hmcl.hmcleadid
    WHERE
      NOT outcomeid IN (5, 15, 19)
      AND sr.createdate >= '2023-11-01' /* and sr.hmcprospectid = 3772411  */
  ) AS sr
    ON sr.hmcrequestid = hmcr.hmcrequestid
  WHERE
    hmcr.affiliateid IN (140, 141)
)
SELECT
  CTE.*,
  CASE WHEN cte.outcomeid IN (12, 14, 16, 17, 18, 20, 22, 24) THEN 1 ELSE 0 END AS Conversation,
  o.outcomename
FROM CTE
LEFT JOIN main.prod_homecare_insite_directory.hmcoutcomes AS o
  ON o.outcomeid = cte.outcomeid
WHERE
  rn = 1
ORDER BY
  hmcprospectid
