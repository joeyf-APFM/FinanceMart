-- Power BI query shape 326 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             233,665,432
-- Rows returned         4,162,260
-- Avg duration          6,514 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  r.referralid,
  r.hmcleadid,
  hmcr.hmcrequestid,
  r.createdon,
  r.billingtypeid,
  r.orderid,
  o.Name AS OrderName,
  r.referredon,
  r.returnapproved,
  r.activatedon,
  r.providerid,
  p.Name AS ProviderName,
  r.digitaljourney
FROM prod_homecare_actransactional_homecare.referral AS r
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = r.providerid
LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = r.orderid
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcleadid = r.hmcleadid
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = hmcl.hmcrequestid
WHERE
  r.digitaljourney = TRUE
