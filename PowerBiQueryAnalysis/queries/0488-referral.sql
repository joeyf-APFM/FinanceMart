-- Power BI query shape 488 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             14,152,147
-- Rows returned         35,594
-- Avg duration          3,745 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ReferralID,
  req.HMCRequestID,
  ActivatedOn,
  req.createdate,
  CAST(ref.ReferredOn AS DATE) AS ReferredOn
FROM prod_homecare_actransactional_homecare.referral AS ref
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  NOT activatedon IS NULL AND ref.Createdon > '2024-01-01'
