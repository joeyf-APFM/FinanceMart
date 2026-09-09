-- Power BI query shape 268 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            103
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,114,952,895
-- Rows returned         77,885,593
-- Avg duration          13,684 ms
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
  AND ref.createdon > DATE_ADD(MONTH, -12, CURRENT_TIMESTAMP())
ORDER BY
  ref.HMCleadID
