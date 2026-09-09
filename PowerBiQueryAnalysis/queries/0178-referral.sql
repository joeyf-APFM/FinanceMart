-- Power BI query shape 178 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            279
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             2,840,686,358
-- Rows returned         422,770,823
-- Avg duration          7,882 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  req.HMCRequestID,
  ReferralID,
  ReferralStatusTypeID,
  Returnapproved,
  CASE WHEN returnapproved = TRUE THEN 1 ELSE 0 END AS return,
  ModifiedOn,
  req.createdate,
  ref.CreatedOn,
  ref.HMCLeadID,
  OrderID
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  (
    BillingTypeID = 3 AND NOT ref.HMCLeadID IS NULL
  )
  AND ref.createdon > '2024-01-01'
ORDER BY
  ref.HMCleadID
