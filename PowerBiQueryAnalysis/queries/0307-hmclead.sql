-- Power BI query shape 307 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            55
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             850,888,465
-- Rows returned         122,937,454
-- Avg duration          8,262 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectphonenumber, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  l.hmcleadid,
  r.firstname,
  r.lastname,
  hmcr.postalcode,
  r.emailaddress,
  rp.phonenumber,
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
    WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 136, 121, 136)
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
  END AS Channel,
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
  END AS DJType
FROM prod_homecare_insite_directory.hmclead AS l
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = l.hmcrequestid
JOIN prod_homecare_insite_directory.hmcprospect AS r
  ON r.hmcprospectid = hmcr.hmcprospectid
JOIN prod_homecare_insite_directory.hmcprospectphonenumber AS rp
  ON rp.hmcprospectid = r.hmcprospectid
WHERE
  hmcr.createdate >= '2023'
