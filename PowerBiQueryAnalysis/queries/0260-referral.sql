-- Power BI query shape 260 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            133
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,502,289,871
-- Rows returned         249,675,799
-- Avg duration          10,341 ms
-- Power BI datasets     c510df23-2b0d-4820-90d4-7aa0d70d29f0
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ref.referralid,
  ref.providerid,
  ref.hmcleadid,
  ref.billingtypeid,
  ref.returnapproved,
  ref.referredon,
  hmcr.createdate,
  hmcr.postalcode
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcleadid = ref.hmcleadid
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = hmcl.hmcrequestid
WHERE
  NOT ref.hmcleadid IS NULL AND ref.billingtypeid = 3 AND hmcr.createdate >= '2024'
