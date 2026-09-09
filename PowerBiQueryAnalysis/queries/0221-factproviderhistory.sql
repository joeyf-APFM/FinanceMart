-- Power BI query shape 221 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             62,220,396
-- Rows returned         57,546,411
-- Avg duration          892 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.factproviderhistory
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    Date,
    AccountID,
    AVG(AccountMonthlyMax) AS AccountMonthlyMax,
    AVG(LeadsSent) AS LeadsSent
  FROM prod_homecare_acreporting_reporting.factproviderhistory
  WHERE
    ContractType = 'CPL'
  GROUP BY
    AccountID,
    Date
  ORDER BY
    Date,
    AccountID
)
SELECT
  Date,
  AccountID,
  CASE WHEN AccountMonthlyMax IS NULL THEN 25 ELSE AccountMonthlyMax END AS AccountMonthlyMax,
  LeadsSent
FROM CTE
ORDER BY
  AccountID,
  Date
