-- Power BI query shape 657 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             6,065,920
-- Rows returned         311,858
-- Avg duration          5,800 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
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
      WHEN hmcr.affiliateid = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid = 138
      THEN 'AgingCare Manual'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    ref.referralid,
    CASE WHEN returnapproved = TRUE THEN 1 ELSE 0 END AS ReturnApproved,
    ref.providerid,
    CAST(ref.referredon AS DATE) AS Referredon,
    CASE
      WHEN hmcr.djstepid = 100
      THEN 'Completed DJ'
      WHEN NOT hmcr.djstepid IS NULL
      THEN 'Dropped from DJ'
      WHEN hmcr.djstepid IS NULL
      THEN 'Not DJ'
    END AS DJ,
    hmcr.djstepid
  FROM prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  WHERE
    ref.referredon >= '2025' AND ref.billingtypeid = 3
)
SELECT
  Referredon,
  COUNT(DISTINCT referralid) AS Referrals,
  ReturnApproved,
  ProviderID
FROM CTE
WHERE
  DJ <> 'Completed DJ' AND NOT AdjChannel IN ('APFM')
GROUP BY
  1,
  3,
  4
