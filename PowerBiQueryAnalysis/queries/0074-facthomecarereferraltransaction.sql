-- Power BI query shape 74 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,158
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             10,021,211,514
-- Rows returned         251,877,738
-- Avg duration          3,550 ms
-- Power BI datasets     e9d48e9c-bb12-4860-b411-434978fd49fe
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
  LeadSentDateID > 20220000 AND LeadSentDateID < 20221100
ORDER BY
  HMCLeadID DESC
