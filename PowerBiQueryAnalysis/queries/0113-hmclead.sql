-- Power BI query shape 113 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            571
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             11,458,262,005
-- Rows returned         1,656,822,824
-- Avg duration          13,645 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, b19514eb-b858-44d5-81a1-2c1a2e9f1483
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
    WHEN hmcr.affiliateid = 140
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
    WHEN hmcr.affiliateid = 112
    THEN 'SEO'
    WHEN hmcr.url IS NULL AND hmcr.affiliateid = 138
    THEN 'AgingCare Manual'
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
