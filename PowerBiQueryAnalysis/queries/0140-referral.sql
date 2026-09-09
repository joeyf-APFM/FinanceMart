-- Power BI query shape 140 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            384
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             2,888,589,073
-- Rows returned         15,374,237
-- Avg duration          3,359 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
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
  ref.ReferredOn
FROM prod_homecare_actransactional_homecare.referral AS ref
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  NOT activatedon IS NULL AND ref.Createdon > '2024-01-01'
