-- Power BI query shape 560 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             10,326,457
-- Rows returned         34,601
-- Avg duration          970 ms
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
  CAST(req.createdate AS DATE) AS createdate,
  CAST(ref.ReferredOn AS DATE) AS ReferredOn
FROM prod_homecare_actransactional_homecare.referral AS ref
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  NOT activatedon IS NULL AND ref.Createdon > '2024-01-01'
