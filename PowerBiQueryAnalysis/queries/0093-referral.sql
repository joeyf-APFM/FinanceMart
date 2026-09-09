-- Power BI query shape 93 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            916
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             8,768,439,066
-- Rows returned         1,177,088,502
-- Avg duration          3,968 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 498b5b81-ab8e-41ee-8683-f1b802ec8635, 75a0183c-2c90-4d23-9c69-cdb19108448e
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
  AND ref.createdon > '2025-01-01'
