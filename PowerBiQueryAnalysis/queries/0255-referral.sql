-- Power BI query shape 255 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            140
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,548,696,036
-- Rows returned         110,576,705
-- Avg duration          5,201 ms
-- Power BI datasets     498b5b81-ab8e-41ee-8683-f1b802ec8635
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  req.HMCRequestID,
  ReferralID, /* ,ReferralStatusTypeID */ /* ,Returnapproved */
  CASE WHEN returnapproved = TRUE THEN 1 ELSE 0 END AS return,
  CAST(ModifiedOn AS DATE) AS ModifiedOn,
  CAST(req.createdate AS DATE) AS createdate,
  ref.CreatedOn
/* ,ref.HMCLeadID */
/*    ,OrderID */
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCLeadID = ref.HMCLeadID
LEFT JOIN prod_homecare_insite_directory.hmcrequest AS req
  ON l.HMCRequestID = req.HMCRequestID
WHERE
  (
    BillingTypeID = 3 AND NOT ref.HMCLeadID IS NULL
  )
  AND ref.createdon >= DATE_ADD(YEAR, -1, DATE_TRUNC('MONTH', CURRENT_TIMESTAMP()))
