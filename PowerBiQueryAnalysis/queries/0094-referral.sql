-- Power BI query shape 94 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            913
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             6,161,438,619
-- Rows returned         32,988,560
-- Avg duration          2,526 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 498b5b81-ab8e-41ee-8683-f1b802ec8635
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  ReferralID,
  req.HMCRequestID,
  CAST(ActivatedOn AS DATE) AS ActivatedOn,
  CAST(req.createdate AS DATE) AS createdate,
  CAST(ref.ReferredOn AS DATE) AS ReferredOn
FROM prod_homecare_actransactional_homecare.referral AS ref
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  NOT activatedon IS NULL AND ref.Createdon > '2025-01-01'
