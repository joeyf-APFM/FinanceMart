-- Power BI query shape 8 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3,224
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             48,891,039,523
-- Rows returned         516,036,592
-- Avg duration          7,475 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    ref.leadid
  FROM prod_homecare_actransactional_homecare.hottransferresult AS hrt
  LEFT JOIN prod_homecare_actransactional_homecare.hottransferresponse AS hr
    ON hr.hottransferresponseid = hrt.hottransferresponseid
  LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.referralid = hrt.referralid
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcrequestid
  WHERE
    hrt.hottransferresponseid = 1
)
SELECT DISTINCT
  ref.leadid,
  CASE
    WHEN NOT cte.leadid IS NULL
    THEN 1
    WHEN NOT hrt.hottransferresponseid IS NULL
    THEN 1
    ELSE 1
  END AS Family_HT_Attempts,
  CASE WHEN NOT cte.leadid IS NULL THEN 1 ELSE 0 END AS Accepted_HT_Families
FROM prod_homecare_actransactional_homecare.hottransferresult AS hrt
LEFT JOIN prod_homecare_actransactional_homecare.hottransferresponse AS hr
  ON hr.hottransferresponseid = hrt.hottransferresponseid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
  ON ref.referralid = hrt.referralid
LEFT JOIN CTE
  ON CTE.leadid = ref.leadid
