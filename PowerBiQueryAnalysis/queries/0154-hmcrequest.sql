-- Power BI query shape 154 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            305
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,754,973,289
-- Rows returned         174,113,713
-- Avg duration          4,538 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hmcr.hmcrequestid,
  hmcr.createdate,
  hmcr.affiliateid,
  screen.attemptcount,
  screen.createdate AS FinalScreenDate,
  djstepid,
  hmcr.requeststatusid,
  hmcr.requeststatuscode,
  screen.outcomeid AS outcomeid,
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
  END AS AdjChannel
FROM prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY hmcrequestid ORDER BY createdate DESC) AS rn
  FROM prod_homecare_insite_directory.hmcscreeningresult
  WHERE
    createdate >= '2024-09-01'
  ORDER BY
    hmcrequestid
) AS screen
  ON screen.hmcrequestid = hmcr.hmcrequestid
WHERE
  NOT affiliateid IN (72, 93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
  AND requeststatusid <> 1
  AND hmcr.createdate >= '2024-10-01'
  AND screen.rn = 1
