-- Power BI query shape 259 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            134
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,060,522,999
-- Rows returned         649,499,631
-- Avg duration          11,334 ms
-- Power BI datasets     c510df23-2b0d-4820-90d4-7aa0d70d29f0
-- Tables                prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  hmcr.hmcrequestid,
  hmcr.createdate AS RequestCreateDate,
  hmcr.requeststatusid,
  TRIM(hmcr.postalcode) AS postalcode,
  hmcl.hmcleadid
FROM prod_homecare_insite_directory.hmcrequest AS hmcr
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
WHERE
  hmcr.createdate >= DATE_ADD(YEAR, -2, CURRENT_TIMESTAMP())
