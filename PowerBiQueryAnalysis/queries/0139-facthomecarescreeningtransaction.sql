-- Power BI query shape 139 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            384
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             4,600,665,267
-- Rows returned         130,233,700
-- Avg duration          4,561 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.facthomecarescreeningtransaction, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ScreeningResultID,
  RequestID,
  ScreeningDateID,
  ScreeningTimeID,
  ScreeningDateTime,
  CareAdivsorInternalUserKey,
  userid,
  ScreeningOutcomeTypeID,
  ScreeningInfoID,
  AttemptCount,
  SecondsInProspect,
  hcrt.HotTransferred
FROM prod_homecare_acreporting_reporting.facthomecarescreeningtransaction AS hcrt
LEFT JOIN prod_homecare_insite_directory.hmcscreeningresult AS sr
  ON hcrt.ScreeningResultID = sr.HMCScreeningResultID
WHERE
  ScreeningDateID > 20240101
