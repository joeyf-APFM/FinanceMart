-- Power BI query shape 148 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            363
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,216,519,169
-- Rows returned         95,795,309
-- Avg duration          6,151 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  hmcr.hmcrequestid,
  hmcr.createdate,
  firstname,
  lastname,
  residentname,
  relation,
  gender,
  age,
  emailaddress,
  hmcr.djstepid,
  CASE WHEN NOT hmcr.djstepid IS NULL THEN 'Started Dj' ELSE 'Not in DJ' END AS IsDJ,
  CASE
    WHEN hmcr.djstepid = 100
    THEN 'Completed In DJ'
    WHEN NOT hmcr.djstepid IS NULL AND hmcr.djstepid <> 100
    THEN 'Dropped from DJ'
  END AS DJStep,
  hmcr.djtypeid,
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
    WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121)
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
    WHEN hmcr.affiliateid = 72
    THEN 'APFM'
    WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
    THEN 'Unknown'
    ELSE 'Affiliates'
  END AS AdjChannel,
  ref.referralid,
  ref.providerid,
  p.name AS ProviderName,
  po.name AS ProviderOrganization,
  ref.orderid,
  ref.ReferredOn,
  ref.ActivatedOn,
  ref.digitaljourney,
  CASE WHEN ref.ActivatedOn IS NULL THEN 0 ELSE 1 END AS Activated
FROM prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = hmcl.hmcleadid
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
WHERE
  NOT hmcr.djstepid IS NULL
