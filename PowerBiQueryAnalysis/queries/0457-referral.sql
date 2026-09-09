-- Power BI query shape 457 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             35,955,641
-- Rows returned         3,734,327
-- Avg duration          3,305 ms
-- Power BI datasets     none recorded
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
