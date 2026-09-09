-- Power BI query shape 382 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             8,517,854
-- Rows returned         32,405
-- Avg duration          351 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralreturnprimaryreasontype, prod_homecare_actransactional_homecare.referralreturnrequest, prod_homecare_actransactional_homecare.referralreturnsecondaryreasontype, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hmcr.hmcrequestid,
  ref.referralid,
  rpt.name AS Primary,
  rsr.name AS Secondary
FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
JOIN main.prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = hmcl.hmcleadid
JOIN main.prod_homecare_actransactional_homecare.referralreturnrequest AS rrr
  ON rrr.referralid = ref.referralid
JOIN main.prod_homecare_actransactional_homecare.referralreturnprimaryreasontype AS rpt
  ON rpt.referralreturnprimaryreasontypeid = rrr.primaryreasontypeid
JOIN main.prod_homecare_actransactional_homecare.referralreturnsecondaryreasontype AS rsr
  ON rsr.referralreturnsecondaryreasontypeid = rrr.secondaryreasontypeid
WHERE
  ref.billingtypeid = 3 AND hmcr.createdate >= '2026'
