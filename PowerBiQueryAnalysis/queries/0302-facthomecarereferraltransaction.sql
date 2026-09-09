-- Power BI query shape 302 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             467,503,401
-- Rows returned         28,121,280
-- Avg duration          4,906 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.facthomecarereferraltransaction, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.lead, prod_homecare_insite_ledger.lead, prod_homecare_reporting_reporting.homecarereportingcploverride
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  hcrt.HMCLeadID,
  hcrt.RequestID,
  ScreeningResultID,
  LeadSentDateID,
  hcrt.AccountID,
  hmcl.CompanyID,
  CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HotTransferred,
  LeadSent,
  LeadReturned,
  CASE
    WHEN hcrt.AccountID = 10435
    THEN 18
    WHEN NOT cplo.CPL IS NULL
    THEN cplo.CPL
    ELSE lld.TransactionAmount
  END AS ReferralRevenue,
  YEAR(ModifiedOn) * 10000 + MONTH(ModifiedOn) * 100 + DAY(ModifiedOn) AS ModifiedDateID
FROM prod_homecare_acreporting_reporting.facthomecarereferraltransaction AS hcrt
LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
  ON hcrt.HMCLeadID = hmcl.HMCLeadID
LEFT JOIN prod_homecare_reporting_reporting.homecarereportingcploverride AS cplo
  ON hcrt.AccountID = cplo.AccountID /* AND CONVERT(DATE, STR(LeadSentDateID)) > cplo.ValidFrom */
LEFT JOIN prod_homecare_insite_directory.lead AS l
  ON hmcl.HMCLeadID = l.HMCLeadID
LEFT JOIN (
  SELECT
    leadid,
    TransactionAmount,
    TransactionType,
    ROW_NUMBER() OVER (PARTITION BY leadid, TransactionType ORDER BY TransactionDate ASC) AS rn
  FROM prod_homecare_insite_ledger.lead
) AS lld
  ON l.leadid = lld.LeadID AND lld.TransactionType = 'DR' AND rn = 1
WHERE
  LeadSentDateID > 20210000
ORDER BY
  HMCLeadID DESC
