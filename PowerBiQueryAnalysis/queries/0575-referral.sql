-- Power BI query shape 575 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             19,269,088
-- Rows returned         112,622
-- Avg duration          1,424 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  COUNT(DISTINCT referralid) AS Referrals,
  CAST(Referredon AS DATE) AS ReferredOn,
  DATE_FORMAT(Referredon, 'yyyyMM') AS MonthYearID,
  CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
  dma.dma
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcleadid = ref.hmcleadid
LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = hmcl.hmcleadid
LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
  ON dma.zip = TRIM(hmcr.postalcode)
WHERE
  NOT ref.hmcleadid IS NULL AND ref.referredon >= '2025' AND ref.billingtypeid = 3
GROUP BY
  2,
  3,
  4,
  5
