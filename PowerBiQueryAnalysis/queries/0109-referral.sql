-- Power BI query shape 109 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            593
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             6,896,715,332
-- Rows returned         1,388,949,030
-- Avg duration          7,075 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ref.referralid,
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
  END AS AdjChannel,
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
  CASE WHEN NOT hmcr.djstepid IS NULL THEN 'Started in DJ' ELSE 'Not DJ' END AS ISDJ,
  CASE
    WHEN NOT hmcr.djstepid IS NULL AND hmcr.djstepid <> 100
    THEN 'Dropped From DJ'
    WHEN hmcr.djstepid = 100
    THEN 'Completed in DJ'
  END AS DJStep
FROM main.prod_homecare_actransactional_homecare.referral AS ref
JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcleadid = ref.hmcleadid
JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = hmcl.hmcrequestid
WHERE
  ref.createdon >= '2023'
