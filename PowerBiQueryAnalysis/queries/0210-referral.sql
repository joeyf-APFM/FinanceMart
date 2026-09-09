-- Power BI query shape 210 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,699,018,960
-- Rows returned         51,083,389
-- Avg duration          4,275 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, 36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  r.HMCRequestID,
  r.HMCProspectID,
  l.hmcLeadID,
  ref.providerid,
  r.postalcode
FROM prod_homecare_insite_directory.hmcrequest AS r
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.hmcrequestid = r.hmcrequestid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = l.hmcleadid
WHERE
  r.createdate > ADD_MONTHS(CURRENT_TIMESTAMP(), -3)
